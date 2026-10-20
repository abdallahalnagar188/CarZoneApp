// Push delivery for customer notifications.
//
// Called by the trg_customer_notifications_send_push trigger (pg_net) with a
// Database Webhook payload for every INSERT on public.customer_notifications.
// Looks up the customer's auth user and their customer-app tokens in
// push_devices, and sends each one an FCM message the app understands
// (lib/core/services/notification_service.dart):
// - data: id (= the row id, the app de-duplicates on it), type, order_id,
//   title_ar, title_en, body_ar, body_en
// - notification: title/body in the customer's language (customers.locale,
//   default ar), so iOS and Android show it while the app is closed.
// Tokens FCM reports as UNREGISTERED are deleted from push_devices.
//
// Security: fails closed. Every request must carry the x-webhook-secret header
// matching PUSH_WEBHOOK_SECRET (the same value is in Vault as
// send_push_webhook_secret for the trigger). The function is deployed with
// --no-verify-jwt, so this header is the only gate.
import type { FcmSend, SendResult } from "./fcm.ts";

export interface NotificationRow {
  id: string;
  customer_id: string;
  type: string;
  title: unknown;
  body: unknown;
  order_id?: string | null;
}

export interface Recipient {
  userId: string | null;
  locale: string | null;
}

export interface Deps {
  webhookSecret: string | undefined;
  getRecipient: (customerId: string) => Promise<Recipient | null>;
  getTokens: (userId: string) => Promise<string[]>;
  deleteTokens: (tokens: string[]) => Promise<void>;
  /** Null when the Firebase service account is missing or invalid. */
  send: FcmSend | null;
}

const ANDROID_CHANNEL = "carzone_orders";

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

function timingSafeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

/** title/body are jsonb {"ar","en"}; tolerate a plain string too. */
export function localizedPair(v: unknown): { ar: string; en: string } {
  if (typeof v === "string") return { ar: v, en: v };
  const t = (v ?? {}) as { ar?: unknown; en?: unknown };
  const ar = typeof t.ar === "string" ? t.ar : "";
  const en = typeof t.en === "string" ? t.en : "";
  return { ar: ar || en, en: en || ar };
}

export const maskToken = (token: string) => `${token.slice(0, 8)}…`;

export function buildMessage(row: NotificationRow, locale: string | null, token: string): Record<string, unknown> {
  const title = localizedPair(row.title);
  const body = localizedPair(row.body);
  const lang = locale === "en" ? "en" : "ar";

  // FCM data values must be strings; leave order_id out rather than send "".
  const data: Record<string, string> = {
    id: row.id,
    type: row.type,
    title_ar: title.ar,
    title_en: title.en,
    body_ar: body.ar,
    body_en: body.en,
  };
  if (row.order_id) data.order_id = row.order_id;

  const apnsHeaders: Record<string, string> = { "apns-priority": "10", "apns-push-type": "alert" };
  // A repeated row id replaces the shown notification instead of stacking (max 64 bytes).
  if (new TextEncoder().encode(row.id).length <= 64) apnsHeaders["apns-collapse-id"] = row.id;

  return {
    token,
    notification: { title: title[lang] || "CarZone", body: body[lang] },
    data,
    android: {
      priority: "HIGH",
      notification: { channel_id: ANDROID_CHANNEL, sound: "default", tag: row.id },
    },
    apns: { headers: apnsHeaders, payload: { aps: { sound: "default" } } },
  };
}

export async function handleSendPush(req: Request, deps: Deps): Promise<Response> {
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });

  if (!deps.webhookSecret) {
    console.error("[send-push] PUSH_WEBHOOK_SECRET is not configured; refusing all requests");
    return json(500, { error: "Push webhook is not configured" });
  }
  if (!timingSafeEqual(req.headers.get("x-webhook-secret") ?? "", deps.webhookSecret)) {
    console.warn("[send-push] rejected request with missing or invalid x-webhook-secret");
    return json(401, { error: "Unauthorized" });
  }

  let payload: { type?: string; table?: string; schema?: string; record?: NotificationRow };
  try {
    payload = await req.json();
  } catch (_) {
    return json(400, { error: "Invalid JSON" });
  }

  const row = payload?.record;
  if (payload?.type !== "INSERT" || payload?.table !== "customer_notifications" || !row?.id || !row?.customer_id) {
    return json(200, { skipped: "not a customer_notifications insert" });
  }

  if (!deps.send) {
    console.error("[send-push] FIREBASE_SERVICE_ACCOUNT is missing or invalid; cannot send", row.id);
    return json(500, { error: "FCM is not configured" });
  }

  const recipient = await deps.getRecipient(row.customer_id);
  if (!recipient?.userId) {
    return json(200, { id: row.id, skipped: "customer has no app account" });
  }

  const tokens = [...new Set(await deps.getTokens(recipient.userId))];
  if (tokens.length === 0) {
    return json(200, { id: row.id, skipped: "no push devices" });
  }

  const results: SendResult[] = await Promise.all(
    tokens.map((t) =>
      deps.send!(buildMessage(row, recipient.locale, t)).catch((e): SendResult => ({
        ok: false,
        status: 0,
        errorCode: "NETWORK",
        message: String(e?.message ?? e),
      }))
    ),
  );

  const dead: string[] = [];
  let sent = 0;
  results.forEach((r, i) => {
    if (r.ok) {
      sent++;
    } else if (r.errorCode === "UNREGISTERED") {
      dead.push(tokens[i]);
    } else {
      console.error(`[send-push] ${row.id} -> ${maskToken(tokens[i])} failed: ${r.status} ${r.errorCode} ${r.message}`);
    }
  });

  if (dead.length) {
    try {
      await deps.deleteTokens(dead);
    } catch (e) {
      console.error("[send-push] could not delete unregistered tokens:", e);
    }
  }

  const failed = tokens.length - sent - dead.length;
  console.log(`[send-push] ${row.id}: sent ${sent}, removed ${dead.length}, failed ${failed}`);
  return json(200, { id: row.id, sent, removed: dead.length, failed });
}
