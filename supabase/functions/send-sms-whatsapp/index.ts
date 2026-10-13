import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

interface SendSmsPayload {
  user: {
    id: string;
    phone: string;
    email?: string;
  };
  sms: {
    otp: string;
  };
}

Deno.serve(async (req: Request) => {
  // Only accept POST requests
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const rawPayload = await req.text();
    const headers = Object.fromEntries(req.headers.entries());

    let payload: SendSmsPayload;

    // 1. Verify webhook signature if secret is configured
    const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
    if (hookSecret && headers["webhook-signature"]) {
      try {
        const cleanSecret = hookSecret.replace("v1,whsec_", "");
        const wh = new Webhook(cleanSecret);
        payload = wh.verify(rawPayload, headers) as SendSmsPayload;
      } catch (verifyErr) {
        console.error("[Send-SMS Hook] Webhook signature verification failed:", verifyErr);
        return new Response(
          JSON.stringify({ error: { message: "Invalid webhook signature" } }),
          { status: 401, headers: { "Content-Type": "application/json" } }
        );
      }
    } else {
      payload = JSON.parse(rawPayload);
    }

    const phone = payload.user?.phone;
    const otp = payload.sms?.otp;

    if (!phone || !otp) {
      console.error("[Send-SMS Hook] Missing phone or OTP in payload:", payload);
      return new Response(
        JSON.stringify({ error: { message: "Missing phone or OTP" } }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`[Send-SMS Hook] Request to send OTP to ${phone}`);

    // 2. Check for WhatsApp Meta Cloud API configuration
    const whatsappToken = Deno.env.get("WHATSAPP_ACCESS_TOKEN");
    const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
    const templateName = Deno.env.get("WHATSAPP_TEMPLATE_NAME"); // optional template name

    if (!whatsappToken || !phoneNumberId) {
      // DEV MODE / SIMULATION: credentials not yet set
      console.log(
        `[Send-SMS Hook] [DEV MODE SIMULATION] WhatsApp credentials not configured. OTP for ${phone} is: ${otp}`
      );
      return new Response(JSON.stringify({ simulated: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. PROD MODE: Deliver via Meta WhatsApp Cloud API
    // Clean phone number (Meta requires digits only, no '+' sign)
    const cleanPhone = phone.replace(/\D/g, "");

    let whatsappBody: Record<string, unknown>;

    if (templateName) {
      // Send as authentication/marketing template
      whatsappBody = {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: cleanPhone,
        type: "template",
        template: {
          name: templateName,
          language: { code: "ar" },
          components: [
            {
              type: "body",
              parameters: [{ type: "text", text: otp }],
            },
            {
              type: "button",
              sub_type: "url",
              index: "0",
              parameters: [{ type: "text", text: otp }],
            },
          ],
        },
      };
    } else {
      // Send as direct text message
      whatsappBody = {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: cleanPhone,
        type: "text",
        text: {
          preview_url: false,
          body: `رمز التحقق الخاص بك في CarZone هو: ${otp}\nلا تشارك هذا الرمز مع أي شخص.`,
        },
      };
    }

    const metaUrl = `https://graph.facebook.com/v21.0/${phoneNumberId}/messages`;
    const response = await fetch(metaUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${whatsappToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(whatsappBody),
    });

    const responseData = await response.json();

    if (!response.ok) {
      console.error("[Send-SMS Hook] Meta WhatsApp API error:", responseData);
      return new Response(
        JSON.stringify({
          error: {
            http_code: response.status,
            message: `Meta API error: ${JSON.stringify(responseData)}`,
          },
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[Send-SMS Hook] WhatsApp message sent successfully to ${phone}`);
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[Send-SMS Hook] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: { message: `Internal server error: ${err}` } }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
