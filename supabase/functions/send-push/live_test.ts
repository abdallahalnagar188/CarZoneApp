// deno test supabase/functions/send-push/live_test.ts
import { assertEquals } from "jsr:@std/assert@1";
import { type Deps, handleSendPush } from "./handler.ts";
import { branchTime, buildLiveMessage, buildLivePayload, type LiveDevice, type LiveOrder } from "./live.ts";
import type { SendResult } from "./fcm.ts";

const SECRET = "s3cret";
// 2026-10-21 12:00 UTC = 15:00 Cairo (summer time until the last Thursday of October).
const NOW = Date.parse("2026-10-21T12:00:00Z");

const ORDER: LiveOrder = {
  id: "ord_1",
  number: "CZ-00123",
  code: "4821",
  status: "confirmed",
  scheduledAt: "2026-10-21T13:30:00Z",
  durationMin: 40,
  branchName: { ar: "فرع المعادي", en: "Maadi" },
  serviceName: { ar: "غسيل كامل", en: "Full wash" },
  serviceStartedAt: null,
};

const IOS: LiveDevice = { id: "d-ios", platform: "ios", fcm_token: "fcm-i", activity_token: "act-i", locale: "ar" };
const ANDROID: LiveDevice = { id: "d-and", platform: "android", fcm_token: "fcm-a", activity_token: null, locale: "en" };

const webhook = (record: unknown) =>
  new Request("https://x.supabase.co/functions/v1/send-push", {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-webhook-secret": SECRET },
    body: JSON.stringify({ type: "UPDATE", table: "orders", schema: "public", record, old_record: null }),
  });

function fakeDeps(order: LiveOrder, devices: LiveDevice[], results: Record<string, SendResult> = {}) {
  const sent: Record<string, unknown>[] = [];
  const deleted: string[] = [];
  const deps: Deps = {
    webhookSecret: SECRET,
    getRecipient: async () => null,
    getTokens: async () => [],
    deleteTokens: async () => {},
    send: async (m) => {
      sent.push(m);
      return results[m.token as string] ?? { ok: true, name: "projects/p/messages/1" };
    },
    live: {
      getOrder: async (id) => (id === order.id ? order : null),
      getDevices: async () => devices,
      deleteDevices: async (ids) => void deleted.push(...ids),
    },
  };
  return { deps, sent, deleted };
}

Deno.test("branch time is shown in Cairo time like FormatHelper.time", () => {
  assertEquals(branchTime(Date.parse("2026-10-21T13:30:00Z"), "ar"), "4:30 م");
  assertEquals(branchTime(Date.parse("2026-10-21T06:05:00Z"), "en"), "9:05 AM");
});

Deno.test("payload matches the app's live booking payload", () => {
  const p = buildLivePayload(ORDER, "ar", NOW);
  assertEquals(p.title, "تم تأكيد حجزك");
  assertEquals(p.subtitle, "موعدك 4:30 م");
  assertEquals(p.stage, 1);
  assertEquals(p.branchName, "فرع المعادي");
  assertEquals(p.isArabic, true);
  assertEquals(p.isFinal, false);
  assertEquals(p.dismissAfterSeconds, null);
  assertEquals((p.stageLabels as string[]).length, 5);
});

Deno.test("in service: ready time counts from the in_service event", () => {
  const p = buildLivePayload(
    { ...ORDER, status: "in_service", serviceStartedAt: "2026-10-21T13:00:00Z" },
    "en",
    NOW,
  );
  assertEquals(p.serviceStartedAt, Date.parse("2026-10-21T13:00:00Z"));
  assertEquals(p.readyAt, Date.parse("2026-10-21T13:40:00Z"));
  assertEquals(p.subtitle, "Ready around 4:40 PM");
});

Deno.test("iOS gets an ActivityKit update with Apple-epoch dates", () => {
  const m = buildLiveMessage(IOS, buildLivePayload(ORDER, "ar", NOW), NOW)!;
  const apns = m.apns as { live_activity_token: string; payload: { aps: Record<string, unknown> } };
  assertEquals(m.token, "fcm-i");
  assertEquals(apns.live_activity_token, "act-i");
  assertEquals(apns.payload.aps.event, "update");
  assertEquals(apns.payload.aps.timestamp, NOW / 1000);
  const state = apns.payload.aps["content-state"] as Record<string, unknown>;
  assertEquals(state.scheduledAt, Date.parse("2026-10-21T13:30:00Z") / 1000 - 978307200);
  assertEquals("readyAt" in state, false);
});

Deno.test("iOS final state ends the activity after the linger time", () => {
  const m = buildLiveMessage(IOS, buildLivePayload({ ...ORDER, status: "completed" }, "ar", NOW), NOW)!;
  const aps = (m.apns as { payload: { aps: Record<string, unknown> } }).payload.aps;
  assertEquals(aps.event, "end");
  assertEquals(aps["dismissal-date"], NOW / 1000 + 900);
});

Deno.test("iOS without an activity token is not sent yet", () => {
  assertEquals(buildLiveMessage({ ...IOS, activity_token: null }, buildLivePayload(ORDER, "ar", NOW), NOW), null);
});

Deno.test("Android gets a silent data message with the full payload", () => {
  const m = buildLiveMessage(ANDROID, buildLivePayload(ORDER, "en", NOW), NOW)!;
  assertEquals("notification" in m, false);
  const data = m.data as Record<string, string>;
  assertEquals(data.kind, "live_booking");
  assertEquals(JSON.parse(data.payload).title, "Your booking is confirmed");
});

Deno.test("orders webhook updates every following device", async () => {
  const { deps, sent, deleted } = fakeDeps(ORDER, [IOS, ANDROID]);
  const res = await handleSendPush(webhook({ id: "ord_1", status: "confirmed" }), deps);
  assertEquals(res.status, 200);
  assertEquals((await res.json()).sent, 2);
  assertEquals(sent.map((m) => m.token), ["fcm-i", "fcm-a"]);
  assertEquals(deleted, []);
});

Deno.test("finished orders and dead tokens stop being followed", async () => {
  const done = fakeDeps({ ...ORDER, status: "completed" }, [IOS, ANDROID]);
  await handleSendPush(webhook({ id: "ord_1" }), done.deps);
  assertEquals(done.deleted.sort(), ["d-and", "d-ios"]);

  const dead = fakeDeps(ORDER, [IOS, ANDROID], { "fcm-a": { ok: false, status: 404, errorCode: "UNREGISTERED" } });
  await handleSendPush(webhook({ id: "ord_1" }), dead.deps);
  assertEquals(dead.deleted, ["d-and"]);
});

Deno.test("orders webhook still needs the secret", async () => {
  const { deps, sent } = fakeDeps(ORDER, [IOS]);
  const req = new Request("https://x.supabase.co/functions/v1/send-push", {
    method: "POST",
    body: JSON.stringify({ type: "UPDATE", table: "orders", record: { id: "ord_1" } }),
  });
  assertEquals((await handleSendPush(req, deps)).status, 401);
  assertEquals(sent.length, 0);
});
