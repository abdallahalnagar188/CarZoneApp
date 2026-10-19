// Supabase Auth "Send SMS" hook: delivers the OTP over the WhatsApp Cloud API.
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

  const whatsappToken = env("WHATSAPP_ACCESS_TOKEN");
  const phoneNumberId = env("WHATSAPP_PHONE_NUMBER_ID");
  const templateName = env("WHATSAPP_TEMPLATE_NAME");

  if (!whatsappToken || !phoneNumberId) {
    if (env("SMS_DEV_SIMULATION") === "true") {
      console.log(`[send-sms] DEV SIMULATION: OTP for ${maskPhone(phone)} not sent (credentials missing)`);
      return json(200, { simulated: true });
    }
    console.error("[send-sms] WhatsApp credentials are not configured");
    return hookError(500, "SMS provider is not configured");
  }

  const to = phone.replace(/\D/g, "");
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
      text: {
        preview_url: false,
        body: `رمز التحقق الخاص بك في CarZone هو: ${otp}\nلا تشارك هذا الرمز مع أي شخص.`,
      },
    };

  try {
    const res = await fetchImpl(`https://graph.facebook.com/v21.0/${phoneNumberId}/messages`, {
      method: "POST",
      headers: { Authorization: `Bearer ${whatsappToken}`, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const detail = await res.text().catch(() => "");
      console.error(`[send-sms] WhatsApp API ${res.status} for ${maskPhone(phone)}: ${detail.slice(0, 500)}`);
      return hookError(502, "Failed to deliver verification code");
    }
  } catch (err) {
    console.error(`[send-sms] WhatsApp API unreachable for ${maskPhone(phone)}:`, err);
    return hookError(502, "Failed to deliver verification code");
  }

  console.log(`[send-sms] OTP delivered to ${maskPhone(phone)}`);
  return json(200, {});
}
