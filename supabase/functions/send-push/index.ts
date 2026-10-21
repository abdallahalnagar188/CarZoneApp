import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { createFcmSender, type FcmSend, parseServiceAccount } from "./fcm.ts";
import { handleSendPush } from "./handler.ts";

// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.
const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

interface Config {
  webhookSecret: string | undefined;
  send: FcmSend | null;
}

let cached: Config | null = null;

// PUSH_WEBHOOK_SECRET / FIREBASE_SERVICE_ACCOUNT come from Edge Function secrets
// when set, otherwise from Vault (send_push_webhook_secret / firebase_service_account)
// through public.send_push_config(), which only service_role may call.
// A complete config is kept for the life of the worker, so the Google access
// token is reused; an incomplete one is re-read on the next request.
async function loadConfig(): Promise<Config> {
  if (cached) return cached;
  let webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  let serviceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!webhookSecret || !serviceAccount) {
    const { data, error } = await db.rpc("send_push_config");
    if (error) console.error("[send-push] could not read Vault config:", error.message);
    webhookSecret ||= data?.send_push_webhook_secret;
    serviceAccount ||= data?.firebase_service_account;
  }
  const sa = parseServiceAccount(serviceAccount);
  const config = { webhookSecret, send: sa ? createFcmSender(sa) : null };
  if (config.webhookSecret && config.send) cached = config;
  return config;
}

// Logic lives in handler.ts so it can be tested with `deno test` (handler_test.ts).
Deno.serve(async (req: Request) =>
  handleSendPush(req, {
    ...(await loadConfig()),
    getRecipient: async (customerId) => {
      const { data, error } = await db.from("customers").select("user_id, locale").eq("id", customerId).maybeSingle();
      if (error) throw error;
      return data ? { userId: data.user_id, locale: data.locale } : null;
    },
    getTokens: async (userId) => {
      const { data, error } = await db.from("push_devices").select("token").eq("user_id", userId).eq("app", "customer");
      if (error) throw error;
      return (data ?? []).map((d) => d.token);
    },
    deleteTokens: async (tokens) => {
      const { error } = await db.from("push_devices").delete().in("token", tokens);
      if (error) throw error;
    },
    live: {
      getOrder: async (orderId) => {
        const { data, error } = await db
          .from("orders")
          .select(
            "id, number, code, status, scheduled_at, duration_min, branches(name), order_items(name, type, position), order_events(status, at)",
          )
          .eq("id", orderId)
          .maybeSingle();
        if (error) throw error;
        if (!data) return null;
        const items = [...(data.order_items ?? [])].sort((a, b) => a.position - b.position);
        const primary = items.find((i) => i.type === "primary") ?? items[0];
        const started = (data.order_events ?? [])
          .filter((e) => e.status === "in_service")
          .map((e) => e.at)
          .sort()
          .pop();
        return {
          id: data.id,
          number: data.number,
          code: data.code,
          status: data.status,
          scheduledAt: data.scheduled_at,
          durationMin: data.duration_min,
          branchName: (data.branches as { name?: unknown } | null)?.name ?? null,
          serviceName: primary?.name ?? null,
          serviceStartedAt: started ?? null,
        };
      },
      getDevices: async (orderId) => {
        const { data, error } = await db
          .from("live_booking_devices")
          .select("id, platform, fcm_token, activity_token, locale")
          .eq("order_id", orderId);
        if (error) throw error;
        return data ?? [];
      },
      deleteDevices: async (ids) => {
        const { error } = await db.from("live_booking_devices").delete().in("id", ids);
        if (error) throw error;
      },
    },
  })
);
