// deno test supabase/functions/send-push/handler_test.ts
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import { buildMessage, type Deps, handleSendPush, localizedPair, type NotificationRow } from "./handler.ts";
import { createFcmSender, fcmErrorCode, parseServiceAccount, type SendResult, signJwt } from "./fcm.ts";

const URL_ = "https://tbcmgdwzarfdgzzmmele.supabase.co/functions/v1/send-push";
const SECRET = "s3cret";

const ROW: NotificationRow = {
  id: "cn_or_123_confirmed",
  customer_id: "cu_1",
  type: "confirmed",
  title: { ar: "تم تأكيد الحجز", en: "Booking Confirmed" },
  body: { ar: "تم تأكيد حجزك رقم #CZ-00123 بنجاح", en: "Your booking #CZ-00123 is confirmed" },
  order_id: "or_123",
};

const webhook = (record: unknown, headers: Record<string, string> = { "x-webhook-secret": SECRET }) =>
  new Request(URL_, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body: JSON.stringify({ type: "INSERT", table: "customer_notifications", schema: "public", record, old_record: null }),
  });

function fakeDeps(over: Partial<Deps> = {}, results: Record<string, SendResult> = {}) {
  const sent: Record<string, unknown>[] = [];
  const deleted: string[] = [];
  const deps: Deps = {
    webhookSecret: SECRET,
    getRecipient: async (id) => (id === "cu_1" ? { userId: "u-1", locale: "ar" } : null),
    getTokens: async () => ["tok-a", "tok-b"],
    deleteTokens: async (t) => void deleted.push(...t),
    send: async (m) => {
      sent.push(m);
      return results[m.token as string] ?? { ok: true, name: "projects/p/messages/1" };
    },
    ...over,
  };
  return { deps, sent, deleted };
}

Deno.test("sends every customer device the message the app expects", async () => {
  const { deps, sent } = fakeDeps();
  const res = await handleSendPush(webhook(ROW), deps);
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { id: ROW.id, sent: 2, removed: 0, failed: 0 });
  assertEquals(sent.map((m) => m.token), ["tok-a", "tok-b"]);
  assertEquals(sent[0].data, {
    id: "cn_or_123_confirmed",
    type: "confirmed",
    order_id: "or_123",
    title_ar: "تم تأكيد الحجز",
    title_en: "Booking Confirmed",
    body_ar: "تم تأكيد حجزك رقم #CZ-00123 بنجاح",
    body_en: "Your booking #CZ-00123 is confirmed",
  });
  assertEquals(sent[0].notification, { title: "تم تأكيد الحجز", body: "تم تأكيد حجزك رقم #CZ-00123 بنجاح" });
});

Deno.test("notification text follows customers.locale, defaulting to Arabic", async () => {
  assertEquals((buildMessage(ROW, "en", "t").notification as { title: string }).title, "Booking Confirmed");
  assertEquals((buildMessage(ROW, null, "t").notification as { title: string }).title, "تم تأكيد الحجز");
  assertEquals((buildMessage(ROW, "fr", "t").notification as { title: string }).title, "تم تأكيد الحجز");
});

Deno.test("message carries Android channel and iOS alert settings", () => {
  const m = buildMessage(ROW, "ar", "t") as {
    android: { priority: string; notification: { channel_id: string; tag: string } };
    apns: { headers: Record<string, string>; payload: { aps: { sound: string } } };
  };
  assertEquals(m.android.priority, "HIGH");
  assertEquals(m.android.notification.channel_id, "carzone_orders");
  assertEquals(m.android.notification.tag, ROW.id);
  assertEquals(m.apns.headers["apns-collapse-id"], ROW.id);
  assertEquals(m.apns.payload.aps.sound, "default");
});

Deno.test("data values are all strings and order_id is omitted when null", () => {
  const m = buildMessage({ ...ROW, type: "offer", order_id: null }, "ar", "t");
  const data = m.data as Record<string, unknown>;
  assertFalse("order_id" in data);
  assert(Object.values(data).every((v) => typeof v === "string"));
});

Deno.test("long ids skip apns-collapse-id (64-byte limit)", () => {
  const m = buildMessage({ ...ROW, id: "x".repeat(65) }, "ar", "t") as { apns: { headers: Record<string, string> } };
  assertFalse("apns-collapse-id" in m.apns.headers);
});

Deno.test("UNREGISTERED tokens are removed, other failures are kept", async () => {
  const { deps, deleted } = fakeDeps({ getTokens: async () => ["dead", "flaky", "ok"] }, {
    dead: { ok: false, status: 404, errorCode: "UNREGISTERED", message: "" },
    flaky: { ok: false, status: 503, errorCode: "UNAVAILABLE", message: "" },
  });
  const res = await handleSendPush(webhook(ROW), deps);
  assertEquals(await res.json(), { id: ROW.id, sent: 1, removed: 1, failed: 1 });
  assertEquals(deleted, ["dead"]);
});

Deno.test("a send that throws counts as failed, not a crash", async () => {
  const { deps } = fakeDeps({
    send: async () => {
      throw new Error("network down");
    },
  });
  assertEquals(await (await handleSendPush(webhook(ROW), deps)).json(), { id: ROW.id, sent: 0, removed: 0, failed: 2 });
});

Deno.test("fails closed without the right webhook secret", async () => {
  const { deps, sent } = fakeDeps();
  assertEquals((await handleSendPush(webhook(ROW, {}), deps)).status, 401);
  assertEquals((await handleSendPush(webhook(ROW, { "x-webhook-secret": "wrong" }), deps)).status, 401);
  assertEquals((await handleSendPush(webhook(ROW), { ...deps, webhookSecret: undefined })).status, 500);
  assertEquals(sent.length, 0);
});

Deno.test("customers without an app account or devices are skipped", async () => {
  const { deps, sent } = fakeDeps({ getTokens: async () => [] });
  assertEquals((await (await handleSendPush(webhook({ ...ROW, customer_id: "cu_none" }), deps)).json()).skipped, "customer has no app account");
  assertEquals((await (await handleSendPush(webhook(ROW), deps)).json()).skipped, "no push devices");
  assertEquals(sent.length, 0);
});

Deno.test("non-insert payloads and other methods are ignored", async () => {
  const { deps, sent } = fakeDeps();
  const update = new Request(URL_, {
    method: "POST",
    headers: { "x-webhook-secret": SECRET },
    body: JSON.stringify({ type: "UPDATE", table: "customer_notifications", record: ROW }),
  });
  assertEquals((await handleSendPush(update, deps)).status, 200);
  assertEquals((await handleSendPush(new Request(URL_), deps)).status, 405);
  assertEquals(sent.length, 0);
});

Deno.test("missing Firebase credentials is a server error", async () => {
  const { deps } = fakeDeps({ send: null });
  assertEquals((await handleSendPush(webhook(ROW), deps)).status, 500);
});

Deno.test("localizedPair tolerates strings and missing languages", () => {
  assertEquals(localizedPair("hi"), { ar: "hi", en: "hi" });
  assertEquals(localizedPair({ en: "Only English" }), { ar: "Only English", en: "Only English" });
  assertEquals(localizedPair(null), { ar: "", en: "" });
});

// ---- fcm.ts ----

async function testServiceAccount() {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(String.fromCharCode(...der)).match(/.{1,64}/g)!.join("\n")}\n-----END PRIVATE KEY-----\n`;
  return { sa: { project_id: "chatapp-188", client_email: "push@chatapp-188.iam.gserviceaccount.com", private_key: pem }, pair };
}

const fromB64url = (s: string) => Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/")), (c) => c.charCodeAt(0));

Deno.test("signJwt produces a verifiable RS256 Google OAuth assertion", async () => {
  const { sa, pair } = await testServiceAccount();
  const jwt = await signJwt(sa, 1_700_000_000);
  const [h, p, s] = jwt.split(".");
  assertEquals(JSON.parse(new TextDecoder().decode(fromB64url(h))), { alg: "RS256", typ: "JWT" });
  const claims = JSON.parse(new TextDecoder().decode(fromB64url(p)));
  assertEquals(claims.iss, sa.client_email);
  assertEquals(claims.scope, "https://www.googleapis.com/auth/firebase.messaging");
  assertEquals(claims.exp - claims.iat, 3600);
  assert(await crypto.subtle.verify("RSASSA-PKCS1-v1_5", pair.publicKey, fromB64url(s), new TextEncoder().encode(`${h}.${p}`)));
});

Deno.test("sender reuses the access token and reports FCM error codes", async () => {
  const { sa } = await testServiceAccount();
  const calls: string[] = [];
  const fakeFetch = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push(url);
    if (url.includes("oauth2")) return Response.json({ access_token: "at-1", expires_in: 3600 });
    assertEquals((init?.headers as Record<string, string>).Authorization, "Bearer at-1");
    const { message } = JSON.parse(String(init?.body));
    if (message.token === "gone") {
      return Response.json({
        error: {
          code: 404,
          status: "NOT_FOUND",
          message: "Requested entity was not found.",
          details: [{ "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError", errorCode: "UNREGISTERED" }],
        },
      }, { status: 404 });
    }
    return Response.json({ name: "projects/chatapp-188/messages/42" });
  }) as typeof fetch;

  const send = createFcmSender(sa, fakeFetch);
  assertEquals(await send({ token: "live" }), { ok: true, name: "projects/chatapp-188/messages/42" });
  const gone = await send({ token: "gone" });
  assertEquals(gone.errorCode, "UNREGISTERED");
  assertEquals(calls.filter((u) => u.includes("oauth2")).length, 1);
  assert(calls[1].endsWith("/v1/projects/chatapp-188/messages:send"));
});

Deno.test("parseServiceAccount accepts raw or base64 JSON and rejects junk", () => {
  const sa = { project_id: "p", client_email: "e", private_key: "k" };
  assertEquals(parseServiceAccount(JSON.stringify(sa)), sa);
  assertEquals(parseServiceAccount(btoa(JSON.stringify(sa))), sa);
  assertEquals(parseServiceAccount("not json"), null);
  assertEquals(parseServiceAccount(undefined), null);
  assertEquals(parseServiceAccount('{"project_id":"p"}'), null);
});

Deno.test("fcmErrorCode falls back to the status", () => {
  assertEquals(fcmErrorCode({ error: { status: "INVALID_ARGUMENT" } }), "INVALID_ARGUMENT");
  assertEquals(fcmErrorCode({}), "UNKNOWN");
});
