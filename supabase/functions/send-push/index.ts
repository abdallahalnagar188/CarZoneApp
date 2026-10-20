import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { createFcmSender, parseServiceAccount } from "./fcm.ts";
import { handleSendPush } from "./handler.ts";

// Secrets (supabase secrets set …): PUSH_WEBHOOK_SECRET, FIREBASE_SERVICE_ACCOUNT.
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.
const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});
const serviceAccount = parseServiceAccount(Deno.env.get("FIREBASE_SERVICE_ACCOUNT"));
// Module scope so the Google access token is reused while the worker is warm.
const send = serviceAccount ? createFcmSender(serviceAccount) : null;

// Logic lives in handler.ts so it can be tested with `deno test` (handler_test.ts).
Deno.serve((req: Request) =>
  handleSendPush(req, {
    webhookSecret: Deno.env.get("PUSH_WEBHOOK_SECRET"),
    send,
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
  })
);
