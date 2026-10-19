// Per-endpoint micro-benchmark of the Supabase REST queries the app sends.
// Runs each endpoint on its own so the slowest query stands out.
// Read-only, anonymous, light load (10 connections x 10s per endpoint by default).
//
// Run:  node qa/load/autocannon_endpoints.js            (from repo root, after `npm i` in qa/)
//       CONNECTIONS=20 DURATION=15 node qa/load/autocannon_endpoints.js
const autocannon = require('autocannon');
const fs = require('fs');
const path = require('path');

const BASE = process.env.SUPABASE_URL || 'https://tbcmgdwzarfdgzzmmele.supabase.co';
const KEY = process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4';
const CONNECTIONS = Number(process.env.CONNECTIONS || 10);
const DURATION = Number(process.env.DURATION || 10);

const ENDPOINTS = [
  ['app_health (healthCheck)', '/rest/v1/app_health?select=*&limit=1'],
  ['areas (home)', '/rest/v1/areas?select=*'],
  ['branches limit 10 (home)', '/rest/v1/branches?select=*&limit=10'],
  ['offers + offer_branches embed (home)', '/rest/v1/offers?select=*,offer_branches(branch_id)&limit=8'],
  ['services limit 25 (home)', '/rest/v1/services?select=*&limit=25'],
  ['branches limit 60 (map)', '/rest/v1/branches?select=*&limit=60'],
  ['branch by id (details)', '/rest/v1/branches?select=*&id=eq.br_nasr'],
  ['services by branch (details)', '/rest/v1/services?select=*&branch_id=eq.br_nasr'],
  ['reviews by branch ordered (details)', '/rest/v1/reviews?select=*&branch_id=eq.br_nasr&order=created_at.desc&limit=25'],
];

function run(name, p) {
  return new Promise((resolve, reject) => {
    autocannon(
      {
        url: BASE + p,
        connections: CONNECTIONS,
        duration: DURATION,
        headers: { apikey: KEY, Authorization: `Bearer ${KEY}`, Accept: 'application/json' },
      },
      (err, res) => (err ? reject(err) : resolve({ name, path: p, res })),
    );
  });
}

(async () => {
  const rows = [];
  for (const [name, p] of ENDPOINTS) {
    process.stdout.write(`-> ${name} ... `);
    const { res } = await run(name, p);
    const non2xx = res.non2xx + res.errors + res.timeouts;
    rows.push({
      endpoint: name,
      req_per_s: Math.round(res.requests.average),
      p50_ms: res.latency.p50,
      p90_ms: res.latency.p90,
      p99_ms: res.latency.p99,
      max_ms: res.latency.max,
      total: res.requests.total,
      errors: non2xx,
      kb_per_req: res.requests.total ? +(res.throughput.total / res.requests.total / 1024).toFixed(1) : 0,
    });
    console.log(`p50=${res.latency.p50}ms p99=${res.latency.p99}ms errors=${non2xx}`);
  }
  console.table(rows);
  const out = path.join(__dirname, '..', 'reports', 'autocannon_endpoints.json');
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, JSON.stringify({ connections: CONNECTIONS, duration_s: DURATION, at: new Date().toISOString(), rows }, null, 2));
  console.log(`saved ${out}`);
})();
