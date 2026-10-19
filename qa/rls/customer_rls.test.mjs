// RLS tests for a signed-in customer. Run against TEST accounts only.
//
//   export CZ_TEST_JWT=...      # customer A (required)   -> see rls/get_token.mjs
//   export CZ_TEST_JWT_B=...    # customer B (optional, enables cross-customer tests)
//   export CZ_ALLOW_WRITES=1    # optional: write tests on A's own test data
//   node --test rls/customer_rls.test.mjs
//
// Read tests never change data. Write tests clean up what they can; the order
// test leaves one cancelled order behind because customers have no DELETE grant.
//
// Several tests here are EXPECTED TO FAIL today: they encode the correct
// behaviour for issues found in the QA review (see docs/qa/QA_REPORT.md).
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';

const URL = process.env.SUPABASE_URL || 'https://tbcmgdwzarfdgzzmmele.supabase.co';
const KEY = process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4';
const JWT_A = process.env.CZ_TEST_JWT;
const JWT_B = process.env.CZ_TEST_JWT_B;
const WRITES = process.env.CZ_ALLOW_WRITES === '1';

const asUser = (jwt) =>
  createClient(URL, KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });

const skipNoA = !JWT_A && 'set CZ_TEST_JWT to run';
const skipNoB = (!JWT_A || !JWT_B) && 'set CZ_TEST_JWT and CZ_TEST_JWT_B to run';
const skipNoWrites = (!JWT_A || !WRITES) && 'set CZ_TEST_JWT and CZ_ALLOW_WRITES=1 to run';

const subOf = (jwt) => JSON.parse(Buffer.from(jwt.split('.')[1], 'base64url').toString()).sub;

let A, me;
before(async () => {
  if (!JWT_A) return;
  A = asUser(JWT_A);
  const { data, error } = await A.from('customers').select('*');
  assert.equal(error, null, error?.message);
  me = data.find((c) => c.user_id === subOf(JWT_A));
  assert.ok(me, 'test customer A has no customers row; sign up in the app first');
});

// ---------- read isolation ----------

test('customers: only my own row is visible', { skip: skipNoA }, async () => {
  const { data } = await A.from('customers').select('id,user_id');
  assert.deepEqual(data.map((c) => c.id), [me.id]);
});

test('current_customer_id() returns my customers.id (not auth uid)', { skip: skipNoA }, async () => {
  const { data, error } = await A.rpc('current_customer_id');
  assert.equal(error, null, error?.message);
  assert.equal(data, me.id);
  assert.notEqual(data, subOf(JWT_A), 'customer id must not equal auth uid');
});

for (const table of ['orders', 'vehicles', 'customer_favorites', 'customer_notifications', 'complaints']) {
  test(`${table}: every visible row belongs to me`, { skip: skipNoA }, async () => {
    const { data, error } = await A.from(table).select('customer_id').limit(500);
    assert.equal(error, null, error?.message);
    const foreign = data.filter((r) => r.customer_id !== me.id);
    assert.equal(foreign.length, 0, `${foreign.length} foreign row(s) visible in ${table}`);
  });
}

test('order_items / order_events only for my orders', { skip: skipNoA }, async () => {
  const mine = new Set((await A.from('orders').select('id')).data.map((o) => o.id));
  for (const t of ['order_items', 'order_events']) {
    const { data, error } = await A.from(t).select('order_id').limit(500);
    assert.equal(error, null, error?.message);
    assert.ok(data.every((r) => mine.has(r.order_id)), `${t} leaks other customers' rows`);
  }
});

test('staff / finance tables are not readable by a customer', { skip: skipNoA }, async () => {
  for (const t of ['businesses', 'payments', 'payouts', 'transactions', 'staff', 'admin_users', 'audit_logs', 'order_notes']) {
    const { data, error } = await A.from(t).select('*').limit(1);
    assert.ok(error || data.length === 0, `customer can read ${t}`);
  }
});

// Bug: the app stores the Supabase access JWT as a "push token" (carzone_db_service.dart updateCustomerToken).
test('push_devices holds push tokens, not Supabase JWTs', { skip: skipNoA }, async () => {
  const { data, error } = await A.from('push_devices').select('token');
  assert.equal(error, null, error?.message);
  const jwts = data.filter((d) => String(d.token).startsWith('eyJ'));
  assert.equal(jwts.length, 0, `${jwts.length} access token(s) stored in push_devices`);
});

test('customer B cannot see customer A orders or vehicles', { skip: skipNoB }, async () => {
  const B = asUser(JWT_B);
  const aOrders = (await A.from('orders').select('id')).data.map((o) => o.id);
  const aCars = (await A.from('vehicles').select('id')).data.map((v) => v.id);
  if (aOrders.length) {
    const { data } = await B.from('orders').select('id').in('id', aOrders);
    assert.equal(data.length, 0, 'B can read A orders');
  }
  if (aCars.length) {
    const { data } = await B.from('vehicles').select('id').in('id', aCars);
    assert.equal(data.length, 0, 'B can read A vehicles');
  }
});

// ---------- writes on A's own data (opt-in) ----------

test('vehicle create + delete round trip', { skip: skipNoWrites }, async () => {
  const id = `veh_qa_${Date.now()}`;
  const ins = await A.from('vehicles').insert({
    id, customer_id: me.id, make: 'QA', model: 'Test', plate: `QA ${Date.now() % 10000}`, color: 'white', is_default: false,
  });
  assert.equal(ins.error, null, ins.error?.message);
  const del = await A.from('vehicles').delete().eq('id', id).select('id');
  assert.equal(del.error, null, del.error?.message);
  assert.equal(del.data.length, 1);
});

test('cannot insert a vehicle for another customer', { skip: skipNoWrites }, async () => {
  const { error } = await A.from('vehicles').insert({
    id: `veh_qa_x_${Date.now()}`, customer_id: 'cu_someone_else', make: 'QA', model: 'X', plate: 'QA X', color: 'red',
  });
  assert.ok(error, 'RLS allowed inserting a vehicle for another customer');
});

test('favorite add + remove round trip', { skip: skipNoWrites }, async () => {
  const branch = (await A.from('branches').select('id').limit(1)).data[0].id;
  await A.from('customer_favorites').delete().eq('customer_id', me.id).eq('branch_id', branch);
  const ins = await A.from('customer_favorites').insert({ customer_id: me.id, branch_id: branch });
  assert.equal(ins.error, null, ins.error?.message);
  const del = await A.from('customer_favorites').delete().eq('customer_id', me.id).eq('branch_id', branch).select();
  assert.equal(del.error, null, del.error?.message);
});

// Mirrors ReviewModel.toJson() exactly. Expected to FAIL until the model matches the schema.
test('review payload sent by the app is accepted', { skip: skipNoWrites }, async () => {
  const done = (await A.from('orders').select('id,branch_id').eq('status', 'completed').limit(1)).data[0];
  if (!done) return assert.ok(true, 'no completed order to review');
  const { error } = await A.from('reviews').insert({
    id: `rv_qa_${Date.now()}`, order_id: done.id, customer_name: me.name, branch_id: done.branch_id,
    service_name: { ar: 'x', en: 'x' }, stars: 5, comment: 'qa', tags: [], reply: null, created_at: new Date().toISOString(),
  });
  assert.equal(error, null, `app review payload rejected: ${error?.message}`);
});

// Requires migration 20261019120000. Leaves one CANCELLED order on the test account.
test('order lifecycle: direct writes blocked, create/cancel via RPC', { skip: skipNoWrites }, async () => {
  const car = (await A.from('vehicles').select('id,plate').limit(1)).data[0];
  assert.ok(car, 'test customer needs at least one vehicle');
  const svc = (await A.from('services').select('id,branch_id').eq('type', 'primary').limit(1)).data[0];

  // QA-C3: a customer can no longer insert an order with a price of their choosing.
  const direct = await A.from('orders').insert({
    number: 'CZ-QA', source: 'app', customer_id: me.id, vehicle_id: car.id, plate: car.plate,
    branch_id: svc.branch_id, business_id: 'x', subtotal: 0, total: 0, duration_min: 30,
    scheduled_at: new Date(Date.now() + 86400000).toISOString(),
  });
  assert.ok(direct.error, 'direct order insert was accepted');

  // Find a bookable slot: next days, 10:00-18:00 Cairo, every 30 min.
  let order;
  for (let d = 1; d <= 6 && !order; d++) {
    for (let h = 10; h < 18 && !order; h += 0.5) {
      const day = new Date(Date.now() + d * 86400000).toISOString().slice(0, 10);
      const hh = String(Math.floor(h)).padStart(2, '0');
      const mm = h % 1 ? '30' : '00';
      const { data, error } = await A.rpc('create_order', {
        p_branch_id: svc.branch_id, p_vehicle_id: car.id, p_primary_service_id: svc.id,
        p_scheduled_at: `${day}T${hh}:${mm}:00+03:00`, p_addon_service_ids: [],
      });
      if (!error) order = data;
      else if (!error.message.startsWith('slot_')) assert.fail(`create_order: ${error.message}`);
    }
  }
  assert.ok(order, 'no bookable slot found in the next 6 days');
  assert.match(order.number, /^CZ-/);

  try {
    // QA-C3: a customer must not be able to rewrite price, payment or status.
    for (const [field, value] of [['total', 0], ['payment_status', 'paid'], ['status', 'completed']]) {
      const { data } = await A.from('orders').update({ [field]: value }).eq('id', order.id).select(field);
      assert.equal(data?.length ?? 0, 0, `customer was able to set orders.${field} = ${value}`);
    }
  } finally {
    const { error } = await A.rpc('cancel_order', { p_order_id: order.id, p_reason: 'QA test' });
    assert.equal(error, null, error?.message);
  }
});

test('sync_customer_profile must not link another customer by phone (manual)', { skip: 'destructive: run only with two disposable accounts, see report' }, () => {});
