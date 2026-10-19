// Read-only security checks for a logged-out client (anon key only).
// Verifies the public catalog is readable and everything personal/financial is not.
//
// Run: node --test rls/anon_access.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';

const URL = process.env.SUPABASE_URL || 'https://tbcmgdwzarfdgzzmmele.supabase.co';
const KEY = process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4';

const db = createClient(URL, KEY, { auth: { persistSession: false } });

const PUBLIC_CATALOG = [
  'areas', 'branches', 'branch_photos', 'branch_amenities', 'amenities',
  'branch_working_hours', 'services', 'service_categories', 'offers', 'offer_branches', 'reviews', 'app_health',
];

const PRIVATE_TABLES = [
  'customers', 'vehicles', 'orders', 'order_items', 'order_events', 'customer_favorites',
  'customer_notifications', 'complaints', 'complaint_notes', 'push_devices', 'payments', 'payouts',
  'transactions', 'businesses', 'business_settings', 'staff', 'staff_shifts', 'admin_users',
  'audit_logs', 'platform_settings', 'wash_applications', 'vendor_notifications', 'admin_notifications',
];

for (const table of PUBLIC_CATALOG) {
  test(`anon can read public catalog: ${table}`, async () => {
    const { data, error } = await db.from(table).select('*').limit(1);
    assert.equal(error, null, error?.message);
    assert.ok(Array.isArray(data));
  });
}

for (const table of PRIVATE_TABLES) {
  test(`anon cannot read private table: ${table}`, async () => {
    const { data, error } = await db.from(table).select('*').limit(1);
    // Either a permission error, or RLS hiding every row, is acceptable.
    assert.ok(error || (Array.isArray(data) && data.length === 0), `anon read ${data?.length} row(s) from ${table}`);
  });
}

test('only active catalog rows are exposed', async () => {
  const branches = await db.from('branches').select('id,active');
  assert.ok(branches.data.every((b) => b.active === true), 'inactive branch visible to anon');
  const services = await db.from('services').select('id,active');
  assert.ok(services.data.every((s) => s.active === true), 'inactive service visible to anon');
  const offers = await db.from('offers').select('id,status');
  assert.ok(offers.data.every((o) => o.status === 'active'), 'non-active offer visible to anon');
  const reviews = await db.from('reviews').select('id,status');
  assert.ok(reviews.data.every((r) => r.status === 'visible'), 'hidden review visible to anon');
});

// Known issue: the branch_shares view runs with the view owner's rights,
// so it bypasses RLS on legacy_branch_shares and leaks auth user UUIDs.
test('branch_shares does not leak user ids to anon', async () => {
  const { data } = await db.from('branch_shares').select('*').limit(5);
  const leaked = (data ?? []).filter((r) => r.user_id);
  assert.equal(leaked.length, 0, `branch_shares exposes ${leaked.length} user_id value(s) to anon`);
});

test('every offer has offer_branches or platform scope', async () => {
  const { data, error } = await db.from('offers').select('id,scope,offer_branches(branch_id)');
  assert.equal(error, null, error?.message);
  const orphan = data.filter((o) => o.scope !== 'platform' && o.offer_branches.length === 0);
  assert.equal(orphan.length, 0, `wash offers without branches: ${orphan.map((o) => o.id)}`);
});

test('every active branch has working hours and at least one primary service', async () => {
  const [b, h, s] = await Promise.all([
    db.from('branches').select('id'),
    db.from('branch_working_hours').select('branch_id'),
    db.from('services').select('branch_id,type'),
  ]);
  const withHours = new Set(h.data.map((r) => r.branch_id));
  const withPrimary = new Set(s.data.filter((r) => r.type === 'primary').map((r) => r.branch_id));
  const missingHours = b.data.filter((r) => !withHours.has(r.id)).map((r) => r.id);
  const missingPrimary = b.data.filter((r) => !withPrimary.has(r.id)).map((r) => r.id);
  assert.deepEqual(missingHours, [], `branches without working hours: ${missingHours}`);
  assert.deepEqual(missingPrimary, [], `branches without a primary service: ${missingPrimary}`);
});

test('cached branch rating matches visible reviews', async () => {
  const [b, r] = await Promise.all([
    db.from('branches').select('id,rating,review_count'),
    db.from('reviews').select('branch_id,stars'),
  ]);
  const agg = {};
  for (const x of r.data) (agg[x.branch_id] ??= []).push(x.stars);
  const drift = b.data.filter((br) => {
    const s = agg[br.id] ?? [];
    const avg = s.length ? s.reduce((a, v) => a + v, 0) / s.length : 0;
    return s.length !== br.review_count || Math.abs(avg - Number(br.rating)) > 0.11;
  });
  assert.deepEqual(
    drift.map((d) => d.id),
    [],
    `rating/review_count out of sync: ${drift.map((d) => `${d.id}(${d.rating}/${d.review_count})`).join(', ')}`,
  );
});
