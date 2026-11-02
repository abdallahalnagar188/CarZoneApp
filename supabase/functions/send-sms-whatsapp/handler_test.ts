// deno test supabase/functions/send-sms-whatsapp/handler_test.ts
// No network: the WhatsApp API is replaced by a stub that records calls.
import { assert, assertEquals } from "jsr:@std/assert@1";
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";
import { handleSendSms, maskPhone } from "./handler.ts";

const SECRET = "v1,whsec_" + btoa("washup-test-secret-0123456789abcdef");
const BASE_ENV: Record<string, string> = {
  SEND_SMS_HOOK_SECRET: SECRET,
  WHATSAPP_ACCESS_TOKEN: "token",
  WHATSAPP_PHONE_NUMBER_ID: "123",
};

function signedRequest(payload: unknown, secret = SECRET): Request {
  const body = JSON.stringify(payload);
  const id = "msg_" + crypto.randomUUID();
  const now = new Date();
  const signature = new Webhook(secret.replace(/^v1,whsec_/, "")).sign(id, now, body);
  return new Request("http://localhost/send-sms", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "webhook-id": id,
      "webhook-timestamp": Math.floor(now.getTime() / 1000).toString(),
      "webhook-signature": signature,
    },
    body,
  });
}

function stubFetch(status = 200) {
  const calls: { url: string; body: any }[] = [];
  const impl = (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), body: JSON.parse(String(init?.body ?? "{}")) });
    return new Response(JSON.stringify({ ok: status < 400 }), { status });
  }) as typeof fetch;
  return { impl, calls };
}

const envOf = (extra: Record<string, string | undefined> = {}) => (n: string) => ({ ...BASE_ENV, ...extra })[n];
const good = { user: { id: "u1", phone: "+201001234567" }, sms: { otp: "123456" } };

Deno.test("unsigned request is rejected and nothing is sent", async () => {
  const { impl, calls } = stubFetch();
  const req = new Request("http://localhost", { method: "POST", body: JSON.stringify(good) });
  const res = await handleSendSms(req, envOf(), impl);
  assertEquals(res.status, 401);
  assertEquals(calls.length, 0);
});

Deno.test("request signed with the wrong secret is rejected", async () => {
  const { impl, calls } = stubFetch();
  const other = "v1,whsec_" + btoa("some-other-secret-0123456789abcdef");
  const res = await handleSendSms(signedRequest(good, other), envOf(), impl);
  assertEquals(res.status, 401);
  assertEquals(calls.length, 0);
});

Deno.test("tampered body after signing is rejected", async () => {
  const { impl, calls } = stubFetch();
  const req = signedRequest(good);
  const forged = new Request(req.url, {
    method: "POST",
    headers: req.headers,
    body: JSON.stringify({ ...good, sms: { otp: "999999" } }),
  });
  assertEquals((await handleSendSms(forged, envOf(), impl)).status, 401);
  assertEquals(calls.length, 0);
});

Deno.test("missing hook secret fails closed", async () => {
  const { impl, calls } = stubFetch();
  const res = await handleSendSms(signedRequest(good), envOf({ SEND_SMS_HOOK_SECRET: undefined }), impl);
  assertEquals(res.status, 500);
  assertEquals(calls.length, 0);
});

Deno.test("arbitrary text in the otp field is refused (no message relay)", async () => {
  const { impl, calls } = stubFetch();
  for (const otp of ["Your account is locked, call 0100", "12345a", "", "1".repeat(20)]) {
    const res = await handleSendSms(signedRequest({ ...good, sms: { otp } }), envOf(), impl);
    assertEquals(res.status, 400, `otp=${otp}`);
  }
  assertEquals(calls.length, 0);
});

Deno.test("malformed phone is refused", async () => {
  const { impl, calls } = stubFetch();
  for (const phone of ["abc", "+0123", "+20100123456789012"]) {
    const res = await handleSendSms(signedRequest({ ...good, user: { id: "u1", phone } }), envOf(), impl);
    assertEquals(res.status, 400, `phone=${phone}`);
  }
  assertEquals(calls.length, 0);
});

Deno.test("valid signed request delivers exactly the OTP to the digits-only number", async () => {
  const { impl, calls } = stubFetch();
  const res = await handleSendSms(signedRequest(good), envOf(), impl);
  assertEquals(res.status, 200);
  assertEquals(calls.length, 1);
  assertEquals(calls[0].body.to, "201001234567");
  assert(calls[0].body.text.body.includes("123456"));
});

Deno.test("template mode passes the OTP as template parameters", async () => {
  const { impl, calls } = stubFetch();
  await handleSendSms(signedRequest(good), envOf({ WHATSAPP_TEMPLATE_NAME: "otp_ar" }), impl);
  assertEquals(calls[0].body.template.name, "otp_ar");
  assertEquals(calls[0].body.template.components[0].parameters[0].text, "123456");
});

Deno.test("provider error is not echoed back to the caller", async () => {
  const { impl } = stubFetch(400);
  const res = await handleSendSms(signedRequest(good), envOf(), impl);
  assertEquals(res.status, 502);
  const body = await res.json();
  assertEquals(body.error.message, "Failed to deliver verification code");
});

Deno.test("missing WhatsApp credentials is an error unless dev simulation is on", async () => {
  const { impl, calls } = stubFetch();
  const noCreds = { WHATSAPP_ACCESS_TOKEN: undefined, WHATSAPP_PHONE_NUMBER_ID: undefined };
  assertEquals((await handleSendSms(signedRequest(good), envOf(noCreds), impl)).status, 500);
  const sim = await handleSendSms(signedRequest(good), envOf({ ...noCreds, SMS_DEV_SIMULATION: "true" }), impl);
  assertEquals(sim.status, 200);
  assertEquals((await sim.json()).simulated, true);
  assertEquals(calls.length, 0);
});

Deno.test("OTP never appears in logs", async () => {
  const lines: string[] = [];
  const orig = { log: console.log, warn: console.warn, error: console.error };
  console.log = console.warn = console.error = (...a: unknown[]) => void lines.push(a.map(String).join(" "));
  try {
    const { impl } = stubFetch();
    await handleSendSms(signedRequest(good), envOf(), impl);
    await handleSendSms(signedRequest(good), envOf({ WHATSAPP_ACCESS_TOKEN: undefined, SMS_DEV_SIMULATION: "true" }), impl);
    await handleSendSms(signedRequest(good), envOf(), stubFetch(500).impl);
  } finally {
    Object.assign(console, orig);
  }
  assert(lines.length > 0);
  assert(lines.every((l) => !l.includes("123456")), lines.join("\n"));
  assert(lines.every((l) => !l.includes("201001234567")), "full phone number logged");
});

const WAPILOT_ENV = { WHATSAPP_PROVIDER: "wapilot", WAPILOT_TOKEN: "wp-token", WAPILOT_INSTANCE_ID: "instance6098" };

Deno.test("wapilot provider sends the OTP text to the QR instance", async () => {
  const calls: { url: string; headers: Headers; body: any }[] = [];
  const impl = (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), headers: new Headers(init?.headers), body: JSON.parse(String(init?.body)) });
    return new Response(JSON.stringify({ success: true, message_id: "m1" }), { status: 200 });
  }) as typeof fetch;
  const req = signedRequest(good);
  const res = await handleSendSms(req, envOf(WAPILOT_ENV), impl);
  assertEquals(res.status, 200);
  assertEquals(calls.length, 1);
  assertEquals(calls[0].url, "https://api.wapilot.net/api/v2/instance6098/send-message");
  assertEquals(calls[0].headers.get("token"), "wp-token");
  assertEquals(calls[0].headers.get("idempotency-key"), `otp-${req.headers.get("webhook-id")}`);
  assertEquals(calls[0].body.chat_id, "201001234567@c.us");
  assert(calls[0].body.text.includes("123456"));
});

Deno.test("wapilot success: false is treated as a failed delivery", async () => {
  const impl = (async () =>
    new Response(JSON.stringify({ success: false, code: "INSTANCE_NOT_READY" }), { status: 200 })) as typeof fetch;
  const res = await handleSendSms(signedRequest(good), envOf(WAPILOT_ENV), impl);
  assertEquals(res.status, 502);
});

Deno.test("wapilot without its credentials is an error, not a fallback to Meta", async () => {
  const { impl, calls } = stubFetch();
  const res = await handleSendSms(signedRequest(good), envOf({ ...WAPILOT_ENV, WAPILOT_TOKEN: undefined }), impl);
  assertEquals(res.status, 500);
  assertEquals(calls.length, 0);
});

Deno.test("provider error echoing the OTP or phone is scrubbed from logs", async () => {
  const lines: string[] = [];
  const orig = console.error;
  console.error = (...a: unknown[]) => void lines.push(a.map(String).join(" "));
  try {
    const impl = (async () =>
      new Response(JSON.stringify({ success: false, chat_id: "201001234567@c.us", text: "code 123456" }), {
        status: 422,
      })) as typeof fetch;
    await handleSendSms(signedRequest(good), envOf(WAPILOT_ENV), impl);
  } finally {
    console.error = orig;
  }
  assert(lines.length > 0);
  assert(lines.every((l) => !l.includes("123456") && !l.includes("201001234567")), lines.join("\n"));
});

Deno.test("maskPhone keeps only the last 3 digits", () => {
  assertEquals(maskPhone("+201001234567"), "+•••••••••567");
});
