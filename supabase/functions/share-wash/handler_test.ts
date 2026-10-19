// deno test supabase/functions/share-wash/handler_test.ts
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import { appDeepLink, branchIdFrom, escapeHtml, handleShareWash } from "./handler.ts";

const BASE = "https://tbcmgdwzarfdgzzmmele.supabase.co/functions/v1/share-wash";
const IPHONE =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1";
const ANDROID = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Mobile Safari/537.36";
const WHATSAPP = "WhatsApp/2.24.10.75 i";
const DESKTOP = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15";

const req = (path: string, ua: string) => new Request(BASE + path, { headers: { "user-agent": ua } });
const nasr = async (id: string) => (id === "br_nasr" ? { name: "كارزن – مدينة نصر", address: "عباس العقاد" } : null);

Deno.test("iPhone Safari is redirected straight into the app", async () => {
  const res = await handleShareWash(req("?id=br_nasr", IPHONE), nasr);
  assertEquals(res.status, 302);
  assertEquals(res.headers.get("location"), "carzone://wash?id=br_nasr");
});

Deno.test("Android Chrome is redirected too", async () => {
  const res = await handleShareWash(req("/br_nasr", ANDROID), nasr);
  assertEquals(res.headers.get("location"), "carzone://wash?id=br_nasr");
});

Deno.test("link-preview bots get the Open Graph page with the branch name", async () => {
  const res = await handleShareWash(req("?id=br_nasr", WHATSAPP), nasr);
  assertEquals(res.status, 200);
  const html = await res.text();
  assert(html.includes('<meta property="og:title" content="كارزن – مدينة نصر | CarZone">'));
  assert(html.includes('href="carzone://wash?id=br_nasr"'));
});

Deno.test("desktop browsers get the page, not a redirect to a scheme they cannot open", async () => {
  assertEquals((await handleShareWash(req("?id=br_nasr", DESKTOP), nasr)).status, 200);
});

Deno.test("vendor-controlled text is escaped (no stored XSS)", async () => {
  const evil = async () => ({ name: '"><script>alert(1)</script>', address: "<img src=x onerror=alert(2)>" });
  const html = await (await handleShareWash(req("?id=br_x", WHATSAPP), evil)).text();
  assertFalse(html.includes("<script>alert(1)"));
  assertFalse(html.includes("<img src=x"));
  assert(html.includes("&#60;script&#62;"));
});

Deno.test("invalid or injected ids never reach the deep link", async () => {
  for (const bad of ['?id="><script>', "?id=br%20nasr", "?id=" + "a".repeat(80), ""]) {
    const res = await handleShareWash(req(bad, IPHONE), nasr);
    assertEquals(res.headers.get("location"), "carzone://", `id ${bad}`);
  }
});

Deno.test("a failing branch lookup still serves a generic page", async () => {
  const boom = async () => {
    throw new Error("db down");
  };
  const res = await handleShareWash(req("?id=br_nasr", WHATSAPP), boom);
  assertEquals(res.status, 200);
  assert((await res.text()).includes("مغسلة سيارات CarZone"));
});

Deno.test("helpers", () => {
  assertEquals(branchIdFrom(new URL(BASE + "?id=br_nasr")), "br_nasr");
  assertEquals(branchIdFrom(new URL(BASE)), null);
  assertEquals(appDeepLink(null), "carzone://");
  assertEquals(escapeHtml(`<a href="x">'&`), "&#60;a href=&#34;x&#34;&#62;&#39;&#38;");
});
