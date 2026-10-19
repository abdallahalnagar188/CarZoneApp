// Share link for a car wash: https://<project>.supabase.co/functions/v1/share-wash?id=<branch id>
//
// Supabase serves Edge Function responses on its default domain as text/plain,
// so the HTML page (and its "open in app" script) never runs in a phone browser.
// Phones are therefore sent straight to the app with a 302 to carzone://wash?id=…,
// which iOS Safari and Android Chrome hand to CarZone. Link-preview bots
// (WhatsApp, Telegram, …) and desktop browsers still get the HTML with Open Graph tags.
// A custom domain would allow real universal links / app links (see QA report).
//
// All branch data is HTML-escaped: names and addresses are written by vendors (QA-M12).

export interface Branch {
  name: string;
  address: string;
}

export type FetchBranch = (id: string) => Promise<Branch | null>;

const BRANCH_ID_RE = /^[A-Za-z0-9_-]{1,64}$/;
const MOBILE_RE = /iPhone|iPad|iPod|Android/i;
const BOT_RE =
  /bot|crawler|spider|preview|facebookexternalhit|whatsapp|telegram|slack|discord|twitter|linkedin|skype|embedly|pinterest|vkshare|quora/i;

const PHOTOS = [
  "photo-1608506375591-b90e1f955e4b",
  "photo-1520340356584-f9917d1eea6f",
  "photo-1761312834165-c27d037b3a6b",
  "photo-1708805282683-50a060eba80f",
  "photo-1761312834150-4beefff097a7",
  "photo-1694678505383-676d78ea3b96",
  "photo-1565689876697-e467b6c54da2",
  "photo-1769641156615-5d561513b3fa",
  "photo-1605164598708-25701594473e",
  "photo-1704796141009-5ed5cc8ca5f3",
];

export const escapeHtml = (s: string) =>
  s.replace(/[&<>"'`]/g, (c) => `&#${c.charCodeAt(0)};`);

export function branchIdFrom(url: URL): string | null {
  const raw = url.searchParams.get("id") ?? url.pathname.split("/").filter(Boolean).pop() ?? "";
  return BRANCH_ID_RE.test(raw) && raw !== "share-wash" ? raw : null;
}

export const appDeepLink = (id: string | null) =>
  id ? `carzone://wash?id=${encodeURIComponent(id)}` : "carzone://";

function photoFor(id: string | null): string {
  let h = 0;
  for (const ch of id ?? "") h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  return `https://images.unsplash.com/${PHOTOS[h % PHOTOS.length]}?auto=format&fit=crop&q=80&w=1200&h=630`;
}

export function renderPage(id: string | null, branch: Branch | null, pageUrl: string): string {
  const name = escapeHtml(branch?.name || "مغسلة سيارات CarZone");
  const address = escapeHtml(branch?.address || "القاهرة، مصر");
  const photo = escapeHtml(photoFor(id));
  const link = escapeHtml(appDeepLink(id));
  const url = escapeHtml(pageUrl);

  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${name} - CarZone</title>
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="CarZone">
  <meta property="og:title" content="${name} | CarZone">
  <meta property="og:description" content="احجز غسيل وتلميع سيارتك الآن في ${name} (${address}) بأفضل الأسعار عبر تطبيق CarZone">
  <meta property="og:image" content="${photo}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:url" content="${url}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${name} | CarZone">
  <meta name="twitter:description" content="احجز غسيل سيارتك الآن في ${name}">
  <meta name="twitter:image" content="${photo}">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      background: linear-gradient(135deg, #062A45 0%, #0B6BA8 100%); color: #fff; min-height: 100vh;
      display: flex; align-items: center; justify-content: center; padding: 20px; }
    .card { background: rgba(255,255,255,0.96); color: #0B1F2E; border-radius: 24px; overflow: hidden;
      max-width: 440px; width: 100%; box-shadow: 0 20px 40px rgba(0,0,0,0.3); text-align: center; }
    .cover-img { width: 100%; height: 220px; object-fit: cover; }
    .content { padding: 24px 20px; }
    .badge { display: inline-block; background: #E6F5FC; color: #0B6BA8; font-weight: 700; font-size: 13px;
      padding: 4px 12px; border-radius: 99px; margin-bottom: 12px; }
    h1 { font-size: 22px; font-weight: 800; margin-bottom: 8px; }
    p { color: #5F7686; font-size: 14px; line-height: 1.5; margin-bottom: 24px; }
    .btn { display: block; background: linear-gradient(135deg, #1FA2E0 0%, #0B6BA8 100%); color: #fff;
      text-decoration: none; font-weight: 700; font-size: 16px; padding: 14px; border-radius: 14px; }
    .footer-note { margin-top: 16px; font-size: 12px; color: #8EA6B6; }
  </style>
</head>
<body>
  <div class="card">
    <img src="${photo}" alt="${name}" class="cover-img">
    <div class="content">
      <span class="badge">🚗 CarZone مغسلة معتمدة</span>
      <h1>${name}</h1>
      <p>📍 ${address}<br>احجز موعدك فوراً واستمتع بغسيل سيارة فائق الجودة بدون انتظار.</p>
      <a href="${link}" class="btn">فتح في تطبيق CarZone</a>
      <div class="footer-note">افتح الرابط من موبايل عليه تطبيق CarZone.</div>
    </div>
  </div>
</body>
</html>`;
}

export async function handleShareWash(req: Request, fetchBranch: FetchBranch): Promise<Response> {
  const url = new URL(req.url);
  const id = branchIdFrom(url);
  const ua = req.headers.get("user-agent") ?? "";

  // A person on a phone: open the app directly.
  if (MOBILE_RE.test(ua) && !BOT_RE.test(ua)) {
    return new Response(null, {
      status: 302,
      headers: { Location: appDeepLink(id), "Cache-Control": "no-store" },
    });
  }

  let branch: Branch | null = null;
  if (id) {
    try {
      branch = await fetchBranch(id);
    } catch (err) {
      console.error("[share-wash] branch lookup failed:", err);
    }
  }

  return new Response(renderPage(id, branch, url.toString()), {
    status: 200,
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "public, max-age=300" },
  });
}
