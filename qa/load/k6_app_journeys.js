// k6 load test that replays the CarZone customer app's real Supabase traffic.
// Every request mirrors a query in lib/core/services/carzone_db_service.dart,
// so the numbers reflect what a phone actually waits for.
//
// Read-only: only anonymous catalog SELECTs (no writes, no auth).
//
// Run:   k6 run qa/load/k6_app_journeys.js
// Tune:  k6 run -e PROFILE=smoke|light|stress qa/load/k6_app_journeys.js
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const BASE = __ENV.SUPABASE_URL || 'https://tbcmgdwzarfdgzzmmele.supabase.co';
// Public anon key (same one shipped in the app, safe for clients).
const KEY = __ENV.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4';

const HEADERS = { apikey: KEY, Authorization: `Bearer ${KEY}`, Accept: 'application/json' };
const REST = `${BASE}/rest/v1`;

const PROFILES = {
  smoke: { stages: [{ duration: '10s', target: 1 }] },
  light: {
    stages: [
      { duration: '20s', target: 10 },
      { duration: '30s', target: 25 },
      { duration: '40s', target: 50 },
      { duration: '20s', target: 0 },
    ],
  },
  stress: {
    stages: [
      { duration: '30s', target: 50 },
      { duration: '1m', target: 100 },
      { duration: '1m', target: 200 },
      { duration: '30s', target: 0 },
    ],
  },
};

const profile = PROFILES[__ENV.PROFILE || 'light'];

export const options = {
  stages: profile.stages,
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<800'],
    home_screen_ms: ['p(95)<1200'],
    search_page_ms: ['p(95)<1200'],
    wash_details_ms: ['p(95)<1200'],
    map_screen_ms: ['p(95)<1500'],
    schema_ok: ['rate>0.99'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

// End-to-end time of each screen (parallel batch = what the user waits for).
const homeMs = new Trend('home_screen_ms', true);
const searchMs = new Trend('search_page_ms', true);
const detailsMs = new Trend('wash_details_ms', true);
const mapMs = new Trend('map_screen_ms', true);
const schemaOk = new Rate('schema_ok');

const get = (path, tag) => ['GET', `${REST}/${path}`, null, { headers: HEADERS, tags: { endpoint: tag } }];

export function setup() {
  const res = http.get(`${REST}/branches?select=id,area_id&limit=60`, { headers: HEADERS });
  const branches = res.json();
  if (!Array.isArray(branches) || branches.length === 0) {
    throw new Error(`setup: could not load branches (${res.status})`);
  }
  return { branchIds: branches.map((b) => b.id), areaIds: [...new Set(branches.map((b) => b.area_id))] };
}

function okJsonArray(r) {
  try {
    return r.status === 200 && Array.isArray(r.json());
  } catch (_) {
    return false;
  }
}

export default function (data) {
  const branchId = data.branchIds[Math.floor(Math.random() * data.branchIds.length)];
  const areaId = data.areaIds[Math.floor(Math.random() * data.areaIds.length)];

  // fetchHomeData(): 4 queries in parallel (Future.wait).
  group('home', () => {
    const t0 = Date.now();
    const rs = http.batch([
      get('areas?select=*', 'areas'),
      get(`branches?select=*&area_id=eq.${areaId}&limit=10`, 'branches_home'),
      get('offers?select=*,offer_branches(branch_id)&limit=8', 'offers_embed'),
      get('services?select=*&limit=25', 'services_home'),
    ]);
    homeMs.add(Date.now() - t0);
    rs.forEach((r) => schemaOk.add(okJsonArray(r)));
    check(rs[1], { 'home branches 200': (r) => r.status === 200 });
  });
  sleep(1 + Math.random() * 2);

  // fetchPaginatedBranches(): page of branches, then their primary services.
  group('search', () => {
    const t0 = Date.now();
    const page = Math.floor(Math.random() * 2);
    const r1 = http.get(`${REST}/branches?select=*&offset=${page * 10}&limit=10`, {
      headers: HEADERS,
      tags: { endpoint: 'branches_page' },
    });
    schemaOk.add(okJsonArray(r1));
    const ids = okJsonArray(r1) ? r1.json().map((b) => b.id) : [];
    if (ids.length) {
      const r2 = http.get(`${REST}/services?select=*&branch_id=in.(${ids.join(',')})&type=eq.primary`, {
        headers: HEADERS,
        tags: { endpoint: 'services_in_branches' },
      });
      schemaOk.add(okJsonArray(r2));
    }
    searchMs.add(Date.now() - t0);
  });
  sleep(1 + Math.random() * 2);

  // fetchBranchDetails(): branch + services + latest 25 reviews in parallel.
  group('wash_details', () => {
    const t0 = Date.now();
    const rs = http.batch([
      get(`branches?select=*&id=eq.${branchId}`, 'branch_one'),
      get(`services?select=*&branch_id=eq.${branchId}`, 'services_branch'),
      get(`reviews?select=*&branch_id=eq.${branchId}&order=created_at.desc&limit=25`, 'reviews_branch'),
    ]);
    detailsMs.add(Date.now() - t0);
    rs.forEach((r) => schemaOk.add(okJsonArray(r)));
    check(rs[0], { 'branch found': (r) => okJsonArray(r) && r.json().length === 1 });
  });
  sleep(1 + Math.random() * 2);

  // fetchMapBranches(): up to 60 branches.
  group('map', () => {
    const t0 = Date.now();
    const r = http.get(`${REST}/branches?select=*&limit=60`, { headers: HEADERS, tags: { endpoint: 'branches_map' } });
    mapMs.add(Date.now() - t0);
    schemaOk.add(okJsonArray(r));
  });
  sleep(2 + Math.random() * 3);
}
