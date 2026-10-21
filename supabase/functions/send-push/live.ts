// Live booking widget updates while the app is closed.
//
// Called through handleSendPush for every status change of an order that a
// device follows (trg_orders_live_push, table live_booking_devices). Builds the
// same payload as the app's LiveBookingService (lib/core/services/live_booking_service.dart)
// and pushes it to each following device:
// - iOS: an ActivityKit push through FCM (apns.live_activity_token) that updates
//   or ends the Live Activity; content-state matches BookingActivityAttributes.ContentState.
// - Android: a silent data message (kind = live_booking) that LiveBookingPushReceiver
//   renders natively with LiveBookingNotifier, without starting Flutter.
// Wording mirrors the live.* keys in lib/core/local/app_translation.dart; keep both in sync.
import type { FcmSend, SendResult } from "./fcm.ts";

export interface LiveOrder {
  id: string;
  number: string;
  code: string;
  status: string;
  scheduledAt: string;
  durationMin: number;
  branchName: unknown;
  serviceName: unknown;
  /** Latest in_service event, if any. */
  serviceStartedAt: string | null;
}

export interface LiveDevice {
  id: string;
  platform: string;
  fcm_token: string;
  activity_token: string | null;
  locale: string | null;
}

export interface LiveDeps {
  getOrder: (orderId: string) => Promise<LiveOrder | null>;
  getDevices: (orderId: string) => Promise<LiveDevice[]>;
  deleteDevices: (ids: string[]) => Promise<void>;
}

type Lang = "ar" | "en";

const STAGES = ["pending", "confirmed", "waiting", "in_service", "completed"];
const UPCOMING = ["pending", "confirmed", "waiting", "in_service"];
/** A final state stays visible this long before the system removes it. */
const FINAL_LINGER_SEC = 15 * 60;
/** Seconds between 1970 and 2001: ActivityKit decodes Date as seconds since 2001. */
const APPLE_EPOCH_SEC = 978307200;

const STRINGS: Record<Lang, Record<string, string>> = {
  ar: {
    "app.name": "كار زون",
    "title.pending": "بانتظار تأكيد المغسلة",
    "title.confirmed": "تم تأكيد حجزك",
    "title.waiting": "سيارتك في المغسلة",
    "title.in_service": "جارٍ غسيل سيارتك",
    "title.completed": "سيارتك جاهزة!",
    "title.cancelled": "تم إلغاء الحجز",
    "title.no_show": "فاتك موعد الحجز",
    "short.pending": "بانتظار التأكيد",
    "short.confirmed": "مؤكد",
    "short.waiting": "وصلت",
    "short.in_service": "جارٍ الغسيل",
    "short.completed": "جاهزة",
    "short.cancelled": "ملغي",
    "short.no_show": "فائت",
    "sub.appointment": "موعدك @time",
    "sub.readyAt": "جاهزة تقريبًا @time",
    "sub.waiting": "في انتظار بدء الخدمة",
    "sub.in_service": "نعمل على سيارتك الآن",
    "sub.completed": "يمكنك استلامها الآن",
    "sub.cancelled": "يمكنك حجز موعد جديد في أي وقت",
    "sub.no_show": "احجز موعدًا جديدًا بسهولة",
    "code": "كود الوصول",
    "stage.pending": "الطلب",
    "stage.confirmed": "التأكيد",
    "stage.waiting": "الوصول",
    "stage.in_service": "الغسيل",
    "stage.completed": "جاهزة",
  },
  en: {
    "app.name": "CarZone",
    "title.pending": "Waiting for the wash to confirm",
    "title.confirmed": "Your booking is confirmed",
    "title.waiting": "Your car is at the wash",
    "title.in_service": "Washing your car",
    "title.completed": "Your car is ready!",
    "title.cancelled": "Booking cancelled",
    "title.no_show": "You missed your booking",
    "short.pending": "Pending",
    "short.confirmed": "Confirmed",
    "short.waiting": "Arrived",
    "short.in_service": "Washing",
    "short.completed": "Ready",
    "short.cancelled": "Cancelled",
    "short.no_show": "Missed",
    "sub.appointment": "Your slot is at @time",
    "sub.readyAt": "Ready around @time",
    "sub.waiting": "Waiting for the service to start",
    "sub.in_service": "We are working on your car",
    "sub.completed": "You can pick it up now",
    "sub.cancelled": "You can book a new slot any time",
    "sub.no_show": "Book a new slot in seconds",
    "code": "Check-in code",
    "stage.pending": "Booked",
    "stage.confirmed": "Confirmed",
    "stage.waiting": "Arrived",
    "stage.in_service": "Washing",
    "stage.completed": "Ready",
  },
};

/** Branch time, as FormatHelper.time shows it: "4:05 م" / "4:05 PM". */
export function branchTime(ms: number, lang: Lang): string {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Africa/Cairo",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).formatToParts(new Date(ms));
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? "";
  const pm = get("dayPeriod").toUpperCase() === "PM";
  return `${get("hour")}:${get("minute")} ${lang === "ar" ? (pm ? "م" : "ص") : pm ? "PM" : "AM"}`;
}

function localized(v: unknown, lang: Lang): string {
  if (typeof v === "string") return v;
  const t = (v ?? {}) as Record<string, unknown>;
  const s = t[lang] ?? t[lang === "ar" ? "en" : "ar"];
  return typeof s === "string" ? s : "";
}

/** Same keys and values as LiveBookingService._payload. */
export function buildLivePayload(order: LiveOrder, locale: string | null, now = Date.now()): Record<string, unknown> {
  const lang: Lang = locale === "en" ? "en" : "ar";
  const tr = (k: string) => STRINGS[lang][k] ?? "";
  const status = order.status;
  const isFinal = !UPCOMING.includes(status);
  const scheduledAt = Date.parse(order.scheduledAt);
  const startedAt = status === "in_service"
    ? (order.serviceStartedAt ? Date.parse(order.serviceStartedAt) : now)
    : null;
  const readyAt = startedAt == null ? null : startedAt + order.durationMin * 60_000;

  let subtitle: string;
  if (status === "pending" || status === "confirmed") {
    subtitle = tr("sub.appointment").replace("@time", branchTime(scheduledAt, lang));
  } else if (status === "in_service" && readyAt != null) {
    subtitle = tr("sub.readyAt").replace("@time", branchTime(readyAt, lang));
  } else {
    subtitle = tr(`sub.${status}`);
  }

  return {
    orderId: order.id,
    number: order.number,
    code: order.code,
    branchName: localized(order.branchName, lang) || tr("app.name"),
    serviceName: localized(order.serviceName, lang),
    status,
    stage: STAGES.indexOf(status),
    title: tr(`title.${status}`),
    shortStatus: tr(`short.${status}`),
    subtitle,
    codeLabel: tr("code"),
    stageLabels: STAGES.map((s) => tr(`stage.${s}`)),
    scheduledAt,
    serviceStartedAt: startedAt,
    readyAt,
    isArabic: lang === "ar",
    isFinal,
    dismissAfterSeconds: isFinal ? FINAL_LINGER_SEC : null,
  };
}

const appleDate = (ms: number) => ms / 1000 - APPLE_EPOCH_SEC;

/** BookingActivityAttributes.ContentState; nil dates are left out. */
export function contentState(p: Record<string, unknown>): Record<string, unknown> {
  const state: Record<string, unknown> = {
    status: p.status,
    stage: p.stage,
    title: p.title,
    shortStatus: p.shortStatus,
    subtitle: p.subtitle,
    scheduledAt: appleDate(p.scheduledAt as number),
    isFinal: p.isFinal,
  };
  if (p.serviceStartedAt != null) state.serviceStartedAt = appleDate(p.serviceStartedAt as number);
  if (p.readyAt != null) state.readyAt = appleDate(p.readyAt as number);
  return state;
}

/** Null when the device cannot be reached yet (iOS before its activity token arrived). */
export function buildLiveMessage(
  device: LiveDevice,
  payload: Record<string, unknown>,
  now = Date.now(),
): Record<string, unknown> | null {
  if (device.platform === "android") {
    return {
      token: device.fcm_token,
      data: { kind: "live_booking", payload: JSON.stringify(payload) },
      // Offline devices only get the latest stage.
      android: { priority: "HIGH", collapse_key: `live_${payload.orderId}` },
    };
  }
  if (device.platform !== "ios" || !device.activity_token) return null;
  const nowSec = Math.floor(now / 1000);
  const aps: Record<string, unknown> = {
    timestamp: nowSec,
    event: payload.isFinal ? "end" : "update",
    "content-state": contentState(payload),
  };
  if (payload.isFinal) aps["dismissal-date"] = nowSec + FINAL_LINGER_SEC;
  return {
    token: device.fcm_token,
    apns: {
      live_activity_token: device.activity_token,
      headers: { "apns-priority": "10" },
      payload: { aps },
    },
  };
}

export async function sendLiveUpdate(
  orderId: string,
  live: LiveDeps,
  send: FcmSend,
): Promise<Record<string, unknown>> {
  const devices = await live.getDevices(orderId);
  if (devices.length === 0) return { order_id: orderId, skipped: "no live devices" };
  const order = await live.getOrder(orderId);
  if (!order) return { order_id: orderId, skipped: "order not found" };

  const now = Date.now();
  const messages = devices.map((d) => buildLiveMessage(d, buildLivePayload(order, d.locale, now), now));
  const results: (SendResult | null)[] = await Promise.all(
    messages.map((m) =>
      m == null ? null : send(m).catch((e): SendResult => ({
        ok: false,
        status: 0,
        errorCode: "NETWORK",
        message: String(e?.message ?? e),
      }))
    ),
  );

  const finished = !UPCOMING.includes(order.status);
  const remove = new Set<string>();
  let sent = 0;
  results.forEach((r, i) => {
    if (r?.ok) sent++;
    else if (r?.errorCode === "UNREGISTERED") remove.add(devices[i].id);
    else if (r) console.error(`[send-push] live ${orderId} -> ${devices[i].platform} failed: ${r.status} ${r.errorCode} ${r.message}`);
  });
  // A finished order is never updated again.
  if (finished) devices.forEach((d) => remove.add(d.id));
  if (remove.size) {
    try {
      await live.deleteDevices([...remove]);
    } catch (e) {
      console.error("[send-push] could not delete live booking devices:", e);
    }
  }

  const waiting = messages.filter((m) => m == null).length;
  console.log(`[send-push] live ${orderId} ${order.status}: sent ${sent} of ${devices.length}, waiting ${waiting}`);
  return { order_id: orderId, status: order.status, sent, waiting, failed: devices.length - sent - waiting };
}
