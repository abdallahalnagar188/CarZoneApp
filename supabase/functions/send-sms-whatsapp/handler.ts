// Supabase Auth "Send SMS" hook: delivers the OTP over WhatsApp.
//
// Provider (WHATSAPP_PROVIDER):
// - "meta" (default): WhatsApp Cloud API with WHATSAPP_ACCESS_TOKEN and
//   WHATSAPP_PHONE_NUMBER_ID, optionally an approved WHATSAPP_TEMPLATE_NAME.
// - "wapilot": a QR-linked Wapilot instance with WAPILOT_TOKEN and
//   WAPILOT_INSTANCE_ID. The webhook id is sent as the Idempotency-Key so a
//   retried hook call does not send the code twice.
//
// Security (QA-C2, QA-M13):
// - Fails closed: every request must carry a valid Standard Webhooks signature
//   made with SEND_SMS_HOOK_SECRET. No secret configured -> 500, nothing is sent.
// - The OTP must be digits only and the phone a plain E.164 number, so the hook
//   cannot be used to send arbitrary text.
// - OTPs are never logged and phones are masked in logs.
// - Dev simulation only when SMS_DEV_SIMULATION=true; otherwise missing WhatsApp
//   credentials are an error, so Supabase Auth reports the failure to the user.
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

export interface SendSmsPayload {
  user: { id: string; phone: string; email?: string };
  sms: { otp: string };
}

export type Env = (name: string) => string | undefined;

const OTP_RE = /^\d{4,10}$/;
const PHONE_RE = /^\+?[1-9]\d{7,14}$/;

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const hookError = (status: number, message: string) => json(status, { error: { http_code: status, message } });

export const maskPhone = (phone: string) => phone.replace(/\d(?=\d{3})/g, "•");

export async function handleSendSms(
  req: Request,
  env: Env = (n) => Deno.env.get(n),
  fetchImpl: typeof fetch = fetch,
): Promise<Response> {
  if (req.method !== "POST") {
    return hookError(405, "Method not allowed");
  }

  const hookSecret = env("SEND_SMS_HOOK_SECRET");
  if (!hookSecret) {
    console.error("[send-sms] SEND_SMS_HOOK_SECRET is not configured; refusing all requests");
    return hookError(500, "SMS hook is not configured");
  }

  const rawPayload = await req.text();
  let payload: SendSmsPayload;
  try {
    const wh = new Webhook(hookSecret.replace(/^v1,whsec_/, ""));
    payload = wh.verify(rawPayload, Object.fromEntries(req.headers.entries())) as SendSmsPayload;
  } catch (_) {
    console.warn("[send-sms] rejected request with missing or invalid webhook signature");
    return hookError(401, "Invalid webhook signature");
  }

  const phone = String(payload?.user?.phone ?? "").replace(/[\s-]/g, "");
  const otp = String(payload?.sms?.otp ?? "");
  if (!PHONE_RE.test(phone) || !OTP_RE.test(otp)) {
    console.warn("[send-sms] rejected payload with invalid phone or OTP format");
    return hookError(400, "Invalid phone or OTP");
  }

  const provider = env("WHATSAPP_PROVIDER") === "wapilot" ? "wapilot" : "meta";
  const to = phone.replace(/\D/g, "");
  const delivery = provider === "wapilot"
    ? wapilotRequest(env, to, otp, req.headers.get("webhook-id"))
    : metaRequest(env, to, otp);

  if (!delivery) {
    if (env("SMS_DEV_SIMULATION") === "true") {
      console.log(`[send-sms] DEV SIMULATION: OTP for ${maskPhone(phone)} not sent (credentials missing)`);
      return json(200, { simulated: true });
    }
    console.error("[send-sms] WhatsApp credentials are not configured");
    return hookError(500, "SMS provider is not configured");
  }

  try {
    const res = await fetchImpl(delivery.url, {
      method: "POST",
      headers: { ...delivery.headers, "Content-Type": "application/json" },
      body: JSON.stringify(delivery.body),
    });
    const detail = await res.text().catch(() => "");
    // Wapilot can answer 200 with success: false, so the body decides too.
    if (!res.ok || /"success"\s*:\s*false/.test(detail)) {
      const safe = detail.replaceAll(otp, "••••").replaceAll(to, maskPhone(to)).slice(0, 500);
      console.error(`[send-sms] ${provider} API ${res.status} for ${maskPhone(phone)}: ${safe}`);
      return hookError(502, "Failed to deliver verification code");
    }
  } catch (err) {
    console.error(`[send-sms] ${provider} API unreachable for ${maskPhone(phone)}:`, err);
    return hookError(502, "Failed to deliver verification code");
  }

  console.log(`[send-sms] OTP delivered to ${maskPhone(phone)} via ${provider}`);
  return json(200, {});
}

interface Delivery {
  url: string;
  headers: Record<string, string>;
  body: unknown;
}

const otpText = (otp: string) => `رمز التحقق الخاص بك في Wash Up هو: ${otp}\nلا تشارك هذا الرمز مع أي شخص.`;

function metaRequest(env: Env, to: string, otp: string): Delivery | null {
  const whatsappToken = env("WHATSAPP_ACCESS_TOKEN");
  const phoneNumberId = env("WHATSAPP_PHONE_NUMBER_ID");
  const templateName = env("WHATSAPP_TEMPLATE_NAME");
  if (!whatsappToken || !phoneNumberId) return null;

  const body = templateName
    ? {
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to,
      type: "template",
      template: {
        name: templateName,
        language: { code: "ar" },
        components: [
          { type: "body", parameters: [{ type: "text", text: otp }] },
          { type: "button", sub_type: "url", index: "0", parameters: [{ type: "text", text: otp }] },
        ],
      },
    }
    : {
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to,
      type: "text",
      text: { preview_url: false, body: otpText(otp) },
    };

  return {
    url: `https://graph.facebook.com/v21.0/${phoneNumberId}/messages`,
    headers: { Authorization: `Bearer ${whatsappToken}` },
    body,
  };
}

function wapilotRequest(env: Env, to: string, otp: string, webhookId: string | null): Delivery | null {
  const token = env("WAPILOT_TOKEN");
  const instanceId = env("WAPILOT_INSTANCE_ID");
  if (!token || !instanceId) return null;

  return {
    url: `https://api.wapilot.net/api/v2/${encodeURIComponent(instanceId)}/send-message`,
    headers: { token, ...(webhookId ? { "Idempotency-Key": `otp-${webhookId}` } : {}) },
    body: { chat_id: `${to}@c.us`, text: otpText(otp) },
  };
}
