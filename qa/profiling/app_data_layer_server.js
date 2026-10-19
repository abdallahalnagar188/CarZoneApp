// Node harness that replays the Flutter app's data layer (CarzoneDbService) with
// supabase-js, so Clinic.js can profile where a client spends its time:
// waiting on Supabase (I/O) vs. parsing/mapping payloads (CPU).
//
// Clinic.js only profiles Node processes; the real app is Flutter + Supabase,
// so this is a faithful stand-in for the client side, not the app itself.
//
//   GET /home          -> fetchHomeData()       (4 parallel queries)
//   GET /search?page=0 -> fetchPaginatedBranches()
//   GET /details/:id   -> fetchBranchDetails()  (3 parallel queries + rating calc)
//   GET /map           -> fetchMapBranches()
//
// Run under Clinic (from qa/):
//   npx clinic doctor --autocannon [ -c 10 -d 20 http://localhost:3999/home ] -- node profiling/app_data_layer_server.js
const http = require('http');
const { createClient } = require('@supabase/supabase-js');

const URL = process.env.SUPABASE_URL || 'https://tbcmgdwzarfdgzzmmele.supabase.co';
const KEY = process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4';
const PORT = Number(process.env.PORT || 3999);

const db = createClient(URL, KEY, { auth: { persistSession: false } });

const unwrap = ({ data, error }) => {
  if (error) throw new Error(`${error.code}: ${error.message}`);
  return data;
};

// Mirrors the model mapping the app does after each fetch (fromJson + localized text).
const mapBranch = (b) => ({
  id: b.id,
  name: b.name?.ar ?? '',
  area: b.area_id,
  lat: Number(b.lat),
  lng: Number(b.lng),
  autoConfirm: !!b.auto_confirm,
  freeCancelMin: b.free_cancel_min ?? 60,
});

async function home() {
  const [areas, branches, offers, services] = await Promise.all([
    db.from('areas').select().then(unwrap),
    db.from('branches').select().limit(10).then(unwrap),
    db.from('offers').select('*, offer_branches(branch_id)').limit(8).then(unwrap),
    db.from('services').select().limit(25).then(unwrap),
  ]);
  return { areas: areas.length, branches: branches.map(mapBranch), offers: offers.length, services: services.length };
}

async function search(page = 0, pageSize = 10) {
  const from = page * pageSize;
  const list = unwrap(await db.from('branches').select().range(from, from + pageSize - 1));
  const ids = list.map((b) => b.id);
  const services = ids.length
    ? unwrap(await db.from('services').select().in('branch_id', ids).eq('type', 'primary'))
    : [];
  return { branches: list.map(mapBranch), services: services.length };
}

async function details(id) {
  const [branch, services, reviews] = await Promise.all([
    db.from('branches').select().eq('id', id).maybeSingle().then(unwrap),
    db.from('services').select().eq('branch_id', id).then(unwrap),
    db.from('reviews').select().eq('branch_id', id).order('created_at', { ascending: false }).limit(25).then(unwrap),
  ]);
  // ratingFor(): the app recomputes the average client-side from loaded reviews.
  const avg = reviews.length ? reviews.reduce((s, r) => s + r.stars, 0) / reviews.length : 0;
  return { branch: branch && mapBranch(branch), services: services.length, reviews: reviews.length, rating: avg };
}

async function map() {
  return (unwrap(await db.from('branches').select().limit(60))).map(mapBranch);
}

const server = http.createServer(async (req, res) => {
  const u = new globalThis.URL(req.url, `http://localhost:${PORT}`);
  try {
    let body;
    if (u.pathname === '/home') body = await home();
    else if (u.pathname === '/search') body = await search(Number(u.searchParams.get('page') || 0));
    else if (u.pathname.startsWith('/details/')) body = await details(u.pathname.split('/')[2]);
    else if (u.pathname === '/map') body = await map();
    else {
      res.writeHead(404).end();
      return;
    }
    res.writeHead(200, { 'content-type': 'application/json' }).end(JSON.stringify(body));
  } catch (e) {
    res.writeHead(502, { 'content-type': 'application/json' }).end(JSON.stringify({ error: e.message }));
  }
});

server.listen(PORT, () => console.log(`app data-layer harness on http://localhost:${PORT}`));
