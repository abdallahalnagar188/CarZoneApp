import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const branchPhotos = [
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

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const branchId = url.searchParams.get("id") || url.pathname.split("/").filter(Boolean).pop() || "br_oasis_nasr";

  let branchName = "مغسلة سيارات CarZone";
  let branchAddress = "القاهرة، مصر";
  let photoSeed = 0;

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    if (supabaseUrl && supabaseAnonKey) {
      const supabase = createClient(supabaseUrl, supabaseAnonKey);
      const { data } = await supabase
        .from("branches")
        .select("id, name, address, photo_seed")
        .eq("id", branchId)
        .maybeSingle();

      if (data) {
        if (typeof data.name === "object" && data.name !== null) {
          branchName = data.name.ar || data.name.en || branchName;
        } else if (typeof data.name === "string") {
          branchName = data.name;
        }

        if (typeof data.address === "object" && data.address !== null) {
          branchAddress = data.address.ar || data.address.en || branchAddress;
        } else if (typeof data.address === "string") {
          branchAddress = data.address;
        }

        photoSeed = Number(data.photo_seed) || 0;
      }
    }
  } catch (err) {
    console.error("Error fetching branch details:", err);
  }

  const photoId = branchPhotos[Math.abs(photoSeed) % branchPhotos.length];
  const photoUrl = `https://images.unsplash.com/${photoId}?auto=format&fit=crop&q=80&w=1200&h=630`;
  const appDeepLink = `carzone://wash?id=${encodeURIComponent(branchId)}`;

  const html = `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${branchName} - CarZone</title>
  
  <!-- Open Graph / WhatsApp / Facebook Meta Tags -->
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="CarZone">
  <meta property="og:title" content="${branchName} | CarZone">
  <meta property="og:description" content="احجز غسيل وتلميع سيارتك الآن في ${branchName} (${branchAddress}) بأفضل الأسعار عبر تطبيق CarZone">
  <meta property="og:image" content="${photoUrl}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:url" content="${req.url}">

  <!-- Twitter Meta Tags -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${branchName} | CarZone">
  <meta name="twitter:description" content="احجز غسيل سيارتك الآن في ${branchName}">
  <meta name="twitter:image" content="${photoUrl}">

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      background: linear-gradient(135deg, #062A45 0%, #0B6BA8 100%);
      color: #ffffff;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: rgba(255, 255, 255, 0.96);
      color: #0B1F2E;
      border-radius: 24px;
      overflow: hidden;
      max-width: 440px;
      width: 100%;
      box-shadow: 0 20px 40px rgba(0,0,0,0.3);
      text-align: center;
      animation: fadeIn 0.4s ease-out;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(12px); }
      to { opacity: 1; transform: translateY(0); }
    }
    .cover-img {
      width: 100%;
      height: 220px;
      object-fit: cover;
    }
    .content {
      padding: 24px 20px;
    }
    .badge {
      display: inline-block;
      background: #E6F5FC;
      color: #0B6BA8;
      font-weight: 700;
      font-size: 13px;
      padding: 4px 12px;
      border-radius: 99px;
      margin-bottom: 12px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      margin-bottom: 8px;
    }
    p {
      color: #5F7686;
      font-size: 14px;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .btn {
      display: block;
      background: linear-gradient(135deg, #1FA2E0 0%, #0B6BA8 100%);
      color: #ffffff;
      text-decoration: none;
      font-weight: 700;
      font-size: 16px;
      padding: 14px;
      border-radius: 14px;
      box-shadow: 0 8px 20px rgba(11, 107, 168, 0.35);
      transition: transform 0.15s ease;
    }
    .btn:active {
      transform: scale(0.98);
    }
    .footer-note {
      margin-top: 16px;
      font-size: 12px;
      color: #8EA6B6;
    }
  </style>

  <script>
    // Automatic deep link dispatch
    window.addEventListener('DOMContentLoaded', function() {
      var isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
      if (isMobile) {
        window.location.href = "${appDeepLink}";
      }
    });
  </script>
</head>
<body>
  <div class="card">
    <img src="${photoUrl}" alt="${branchName}" class="cover-img">
    <div class="content">
      <span class="badge">🚗 CarZone مغسلة معتمدة</span>
      <h1>${branchName}</h1>
      <p>📍 ${branchAddress}<br>احجز موعدك فوراً واستمتع بغسيل سيارة فائق الجودة بدون انتظار.</p>
      <a href="${appDeepLink}" class="btn">فتح في تطبيق CarZone</a>
      <div class="footer-note">إذا كان التطبيق مثبتاً على هاتفك، سيتم الفتح تلقائياً.</div>
    </div>
  </div>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=300",
    },
  });
});
