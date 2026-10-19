// Runs the real migrations against PGlite (Postgres 17 in WASM) on a schema that
// mirrors supabase/database.types.ts, then attacks them as anon / customer / staff.
//
// Run: node --test db/security_phase1.test.mjs
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const root = fileURLToPath(new URL('../../', import.meta.url));
const sql = (p) => readFileSync(root + p, 'utf8');

const U = {
  ahmed: '11111111-1111-1111-1111-111111111111', // verified phone +201001234567 (seeded, unlinked customer)
  ahmed2: '11111111-1111-1111-1111-222222222222', // a second auth account with the same verified phone
  google: '22222222-2222-2222-2222-222222222222', // Google sign-in, no verified phone
  attacker: '33333333-3333-3333-3333-333333333333', // verified phone of their own
  other: '44444444-4444-4444-4444-444444444444', // another existing customer
  staff: '55555555-5555-5555-5555-555555555555', // staff at br_a
};

let db;

async function as(uid, fn) {
  return db.transaction(async (tx) => {
    if (uid) {
      await tx.exec('SET LOCAL ROLE authenticated');
      await tx.query("SELECT set_config('request.jwt.claim.sub', $1, true)", [uid]);
    } else {
      await tx.exec('SET LOCAL ROLE anon');
    }
    return fn(tx);
  });
}

const one = async (tx, q, params = []) => (await tx.query(q, params)).rows[0];

async function rejects(promise, msg) {
  await assert.rejects(promise, (e) => {
    assert.match(e.message, msg instanceof RegExp ? msg : new RegExp(`^${msg}$`));
    return true;
  });
}

// A Cairo-local slot `daysAhead` days from now at HH:MM, skipping Fridays (closed).
async function slot(hhmm = '10:00', { daysAhead = 2, friday = false } = {}) {
  const r = await db.query(
    `SELECT ((d::date + $1::time) AT TIME ZONE 'Africa/Cairo') AS at
     FROM generate_series((now() AT TIME ZONE 'Africa/Cairo')::date + $2::int,
                          (now() AT TIME ZONE 'Africa/Cairo')::date + $2::int + 7, interval '1 day') d
     WHERE (extract(dow FROM d) = 5) = $3
     ORDER BY d LIMIT 1`,
    [hhmm, daysAhead, friday],
  );
  return r.rows[0].at;
}

const createOrder = (tx, { branch = 'br_a', vehicle = 'veh_ahmed', primary = 'svc_ext', addons = [], at }) =>
  one(tx, 'SELECT public.create_order($1, $2, $3, $4, $5) AS o', [branch, vehicle, primary, at, addons]).then((r) => r.o);

before(async () => {
  db = new PGlite();
  await db.exec(sql('qa/db/mock_schema.sql'));
  await db.exec(sql('supabase/migrations/20261016183000_customer_app_integration.sql'));
  await db.exec(sql('supabase/migrations/20261019120000_security_phase1.sql'));
  // Applying it twice must be safe.
  await db.exec(sql('supabase/migrations/20261019120000_security_phase1.sql'));

  await db.exec(`
    INSERT INTO auth.users (id, phone) VALUES
      ('${U.ahmed}', '201001234567'), ('${U.ahmed2}', '201001234567'), ('${U.google}', NULL),
      ('${U.attacker}', '201009999999'), ('${U.other}', '201002222222'), ('${U.staff}', '201005555555');
    INSERT INTO public.businesses (id, status) VALUES ('biz_a', 'active'), ('biz_s', 'suspended');
    INSERT INTO public.branches (id, business_id, capacity, auto_confirm) VALUES
      ('br_a', 'biz_a', 1, false), ('br_auto', 'biz_a', 2, true), ('br_susp', 'biz_s', 2, false), ('br_b', 'biz_a', 2, false);
    INSERT INTO public.branch_working_hours (branch_id, weekday, opens_at, closes_at, closed)
      SELECT b, d, '09:00', '00:00', d = 5 FROM unnest(ARRAY['br_a','br_auto','br_susp','br_b']) b, generate_series(0, 6) d;
    INSERT INTO public.services (id, branch_id, type, category_id, price, duration_min) VALUES
      ('svc_ext', 'br_a', 'primary', 'exterior', 100, 30),
      ('svc_full', 'br_a', 'primary', 'full', 250, 60),
      ('svc_wax', 'br_a', 'addon', 'addon', 40, 15),
      ('svc_auto', 'br_auto', 'primary', 'exterior', 80, 30),
      ('svc_susp', 'br_susp', 'primary', 'exterior', 80, 30),
      ('svc_b_addon', 'br_b', 'addon', 'addon', 10, 10);
    INSERT INTO public.offers (id, discount_type, discount_value, starts_at, ends_at) VALUES
      ('of_ext', 'percent', 15, now() - interval '1 day', now() + interval '30 days'),
      ('of_fixed', 'fixed', 20, now() - interval '1 day', now() + interval '30 days'),
      ('of_expired', 'percent', 90, now() - interval '9 days', now() - interval '1 day');
    INSERT INTO public.offer_branches VALUES ('of_ext', 'br_a'), ('of_fixed', 'br_auto'), ('of_expired', 'br_a');
    INSERT INTO public.offer_categories VALUES ('of_ext', 'exterior');
    INSERT INTO public.customers (id, user_id, name, phone) VALUES
      ('cu_ahmed', NULL, 'Ahmed Hassan', '+201001234567'),
      ('cu_other', '${U.other}', 'Other', '+201002222222');
    INSERT INTO public.vehicles (id, customer_id, make, model, color, plate) VALUES
      ('veh_ahmed', 'cu_ahmed', 'Toyota', 'Corolla', 'white', 'ABC 123'),
      ('veh_other', 'cu_other', 'Kia', 'Rio', 'red', 'XYZ 999');
    INSERT INTO public.staff (id, user_id, branch_id, business_id) VALUES ('st_1', '${U.staff}', 'br_a', 'biz_a');
  `);
});

// ---------------------------------------------------------------- C1 --------

test('C1 anon cannot call sync_customer_profile', async () => {
  await rejects(as(null, (tx) => tx.query("SELECT public.sync_customer_profile('+201001234567', 'x')")), /permission denied/);
});

test('C1 Google user typing a registered phone is refused and links nothing', async () => {
  await rejects(as(U.google, (tx) => tx.query("SELECT public.sync_customer_profile('+20 100 123 4567', 'Hacker')")), 'phone_in_use');
  const r = await db.query("SELECT user_id FROM public.customers WHERE id = 'cu_ahmed'");
  assert.equal(r.rows[0].user_id, null);
});

test('C1 attacker with their own verified phone cannot claim the victim by passing the victim phone', async () => {
  const r = await as(U.attacker, (tx) => one(tx, "SELECT public.sync_customer_profile('+201001234567', 'Attacker') AS c"));
  assert.notEqual(r.c.id, 'cu_ahmed');
  assert.equal(r.c.phone, '+201009999999', 'new row must use the verified phone, not the typed one');
  const v = await db.query("SELECT user_id FROM public.customers WHERE id = 'cu_ahmed'");
  assert.equal(v.rows[0].user_id, null, 'victim row must stay unlinked');
});

test('C1 the verified owner links their seeded customer row', async () => {
  const r = await as(U.ahmed, (tx) => one(tx, "SELECT public.sync_customer_profile('+201001234567') AS c"));
  assert.equal(r.c.id, 'cu_ahmed');
  assert.equal(r.c.user_id, U.ahmed);
});

test('C1 a second account with the same phone cannot take over a linked row', async () => {
  await rejects(as(U.ahmed2, (tx) => tx.query("SELECT public.sync_customer_profile('+201001234567', 'Ahmed 2')")), 'phone_in_use');
  const v = await db.query("SELECT user_id FROM public.customers WHERE id = 'cu_ahmed'");
  assert.equal(v.rows[0].user_id, U.ahmed);
});

test('C1 Google user with a free phone gets a new profile only once a name is given', async () => {
  const noName = await as(U.google, (tx) => one(tx, "SELECT public.sync_customer_profile('+201007777777') AS c"));
  assert.equal(noName.c, null);
  const r = await as(U.google, (tx) => one(tx, "SELECT public.sync_customer_profile('+201007777777', 'Google User') AS c"));
  assert.equal(r.c.user_id, U.google);
  assert.equal(r.c.phone, '+201007777777');
});

test('C1 customers cannot insert their own customers row directly', async () => {
  await rejects(
    as(U.ahmed2, (tx) => tx.query("INSERT INTO public.customers (user_id, name, phone) VALUES ($1, 'x', '+201002222222')", [U.ahmed2])),
    /row-level security/,
  );
});

test('C1 customer can rename themselves but not change phone or status', async () => {
  const r = await as(U.ahmed, (tx) => tx.query("UPDATE public.customers SET name = 'Ahmed H.' WHERE id = 'cu_ahmed'"));
  assert.equal(r.affectedRows, 1);
  await rejects(as(U.ahmed, (tx) => tx.query("UPDATE public.customers SET phone = '+201002222222' WHERE id = 'cu_ahmed'")), 'customer_field_locked');
  await rejects(as(U.ahmed, (tx) => tx.query("UPDATE public.customers SET status = 'suspended' WHERE id = 'cu_ahmed'")), 'customer_field_locked');
});

// ---------------------------------------------------------------- C3 --------

let ahmedOrder;

test('C3 customer cannot insert an order directly', async () => {
  const at = await slot('12:00');
  await rejects(
    as(U.ahmed, (tx) =>
      tx.query(
        `INSERT INTO public.orders (number, source, customer_id, vehicle_id, plate, business_id, branch_id, subtotal, total, duration_min, scheduled_at)
         VALUES ('CZ-1', 'app', 'cu_ahmed', 'veh_ahmed', 'ABC 123', 'biz_a', 'br_a', 0, 0, 30, $1)`,
        [at],
      ),
    ),
    /row-level security/,
  );
});

test('C3/C4 create_order prices, numbers and validates on the server', async () => {
  const at = await slot('10:00');
  const o = await as(U.ahmed, (tx) => createOrder(tx, { addons: ['svc_wax'], at }));
  ahmedOrder = o;
  assert.match(o.number, /^CZ-\d+$/);
  assert.equal(o.customer_id, 'cu_ahmed');
  assert.equal(Number(o.subtotal), 140);
  assert.equal(Number(o.discount_amount), 15, '15% exterior offer on the primary service only');
  assert.equal(Number(o.total), 125);
  assert.equal(o.offer_id, 'of_ext');
  assert.equal(o.duration_min, 45);
  assert.equal(o.status, 'pending');
  assert.equal(o.plate, 'ABC 123');
  assert.deepEqual(o.order_items.map((i) => i.service_id), ['svc_ext', 'svc_wax']);
  assert.deepEqual(o.order_events.map((e) => e.status), ['pending']);
});

test('C3 customer cannot rewrite price, status or payment, even with a leftover permissive policy', async () => {
  await db.exec(`CREATE POLICY "Rogue customer update" ON public.orders FOR UPDATE TO authenticated
                 USING (customer_id = public.current_customer_id()) WITH CHECK (true)`);
  try {
    for (const set of ["total = 0", "status = 'completed'", "payment_status = 'paid'", "discount_amount = 140"]) {
      const r = await as(U.ahmed, (tx) => tx.query(`UPDATE public.orders SET ${set} WHERE id = $1`, [ahmedOrder.id]));
      assert.equal(r.affectedRows, 0, `customer changed: ${set}`);
    }
    const row = (await db.query('SELECT total, status, payment_status FROM public.orders WHERE id = $1', [ahmedOrder.id])).rows[0];
    assert.deepEqual([Number(row.total), row.status, row.payment_status], [125, 'pending', 'pending']);
  } finally {
    await db.exec('DROP POLICY "Rogue customer update" ON public.orders');
  }
});

test('C3 customer cannot add items or events to their order directly', async () => {
  await rejects(
    as(U.ahmed, (tx) =>
      tx.query(`INSERT INTO public.order_items (order_id, name, type, price, duration_min) VALUES ($1, '{}', 'addon', -100, 0)`, [ahmedOrder.id]),
    ),
    /row-level security/,
  );
  await rejects(
    as(U.ahmed, (tx) => tx.query(`INSERT INTO public.order_events (order_id, status, actor_type, actor_id) VALUES ($1, 'completed', 'staff', 'x')`, [ahmedOrder.id])),
    /row-level security/,
  );
});

test('C3 staff can still update orders at their branch (vendor panel unaffected)', async () => {
  const r = await as(U.staff, (tx) => tx.query("UPDATE public.orders SET status = 'confirmed' WHERE id = $1", [ahmedOrder.id]));
  assert.equal(r.affectedRows, 1);
});

test('slot full: second booking in the same slot is refused (capacity 1)', async () => {
  const at = await slot('10:00');
  await rejects(as(U.other, (tx) => createOrder(tx, { vehicle: 'veh_other', at })), 'slot_unavailable');
});

test('slot rules: closed day, misaligned, too soon, too far, past closing, blocked', async () => {
  const run = (at, primary = 'svc_ext') => as(U.ahmed, (tx) => createOrder(tx, { primary, at }));
  await rejects(run(await slot('10:00', { friday: true })), 'slot_outside_hours');
  await rejects(run(await slot('10:10')), 'slot_outside_hours');
  await rejects(run(await slot('08:30')), 'slot_outside_hours');
  await rejects(run(await slot('23:30'), 'svc_full'), 'slot_outside_hours'); // 60 min past midnight close
  await rejects(run(new Date(Date.now() + 5 * 60 * 1000).toISOString()), 'slot_too_soon');
  await rejects(run(await slot('10:00', { daysAhead: 9 })), 'slot_too_far');

  const blocked = await slot('15:00');
  await db.query(
    "INSERT INTO public.branch_blocked_slots (branch_id, starts_at, ends_at) VALUES ('br_a', $1::timestamptz - interval '30 min', $1::timestamptz + interval '1 hour')",
    [blocked],
  );
  await rejects(run(blocked), 'slot_unavailable');
});

test('booking input is validated: foreign vehicle, foreign add-on, primary as add-on, suspended business', async () => {
  const at = await slot('13:00');
  await rejects(as(U.ahmed, (tx) => createOrder(tx, { vehicle: 'veh_other', at })), 'vehicle_not_found');
  await rejects(as(U.ahmed, (tx) => createOrder(tx, { addons: ['svc_b_addon'], at })), 'invalid_addon');
  await rejects(as(U.ahmed, (tx) => createOrder(tx, { addons: ['svc_full'], at })), 'invalid_addon');
  await rejects(as(U.ahmed, (tx) => createOrder(tx, { primary: 'svc_wax', at })), 'service_not_found');
  await rejects(as(U.ahmed, (tx) => createOrder(tx, { branch: 'br_susp', primary: 'svc_susp', at })), 'branch_unavailable');
});

test('auto-confirm branch: fixed offer, confirmed status, two events', async () => {
  const at = await slot('11:00');
  const o = await as(U.ahmed, (tx) => createOrder(tx, { branch: 'br_auto', primary: 'svc_auto', at }));
  assert.equal(Number(o.total), 60);
  assert.equal(o.status, 'confirmed');
  assert.deepEqual(o.order_events.map((e) => e.status), ['pending', 'confirmed']);
});

test('cancel_order: only the owner, only while pending/confirmed', async () => {
  const at = await slot('16:00');
  const o = await as(U.ahmed, (tx) => createOrder(tx, { at }));
  await rejects(as(U.other, (tx) => tx.query("SELECT public.cancel_order($1, 'x')", [o.id])), 'order_not_found');
  const c = await as(U.ahmed, (tx) => one(tx, "SELECT public.cancel_order($1, 'cancel.r1') AS o", [o.id])).then((r) => r.o);
  assert.equal(c.status, 'cancelled');
  assert.equal(c.cancelled_by_id, 'cu_ahmed');
  assert.equal(c.late_cancel, false);
  assert.deepEqual(c.order_events.map((e) => e.status), ['pending', 'cancelled']);
  await rejects(as(U.ahmed, (tx) => tx.query("SELECT public.cancel_order($1, 'again')", [o.id])), 'order_not_cancellable');
});

test('reschedule_order: moves within rules, refuses a full slot, keeps its own seat', async () => {
  const at = await slot('17:00');
  const o = await as(U.ahmed, (tx) => createOrder(tx, { at }));
  // 10:00 is full (Ahmed's confirmed order, capacity 1).
  const full = await slot('10:00');
  await rejects(as(U.ahmed, (tx) => tx.query('SELECT public.reschedule_order($1, $2)', [o.id, full])), 'slot_unavailable');
  // Same slot again is fine: the order does not block itself.
  const same = await as(U.ahmed, (tx) => one(tx, 'SELECT public.reschedule_order($1, $2) AS o', [o.id, at])).then((r) => r.o);
  assert.equal(new Date(same.scheduled_at).getTime(), new Date(at).getTime());
  const later = await slot('17:30');
  const moved = await as(U.ahmed, (tx) => one(tx, 'SELECT public.reschedule_order($1, $2) AS o', [o.id, later])).then((r) => r.o);
  assert.equal(new Date(moved.scheduled_at).getTime(), new Date(later).getTime());
  await rejects(as(U.other, (tx) => tx.query('SELECT public.reschedule_order($1, $2)', [o.id, later])), 'order_not_found');
});

test('suspended customers cannot book', async () => {
  await db.query("UPDATE public.customers SET status = 'suspended' WHERE id = 'cu_other'");
  await rejects(as(U.other, (tx) => createOrder(tx, { vehicle: 'veh_other', at: '2030-01-01T10:00:00Z' })), 'account_suspended');
});

test('anon cannot call the booking RPCs', async () => {
  await rejects(as(null, (tx) => createOrder(tx, { at: '2030-01-01T10:00:00Z' })), /permission denied/);
  await rejects(as(null, (tx) => tx.query("SELECT public.cancel_order('x')")), /permission denied/);
});

test('customer still reads their own orders (and only theirs)', async () => {
  const mine = await as(U.ahmed, (tx) => tx.query('SELECT customer_id FROM public.orders'));
  assert.ok(mine.rows.length >= 3);
  assert.ok(mine.rows.every((r) => r.customer_id === 'cu_ahmed'));
});
