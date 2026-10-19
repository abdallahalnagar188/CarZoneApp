import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { type Branch, handleShareWash } from "./handler.ts";

function localized(v: unknown): string {
  if (typeof v === "string") return v;
  const text = v as { ar?: string; en?: string } | null;
  return text?.ar || text?.en || "";
}

async function fetchBranch(id: string): Promise<Branch | null> {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !key) return null;
  const { data, error } = await createClient(url, key)
    .from("branches")
    .select("name, address")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data ? { name: localized(data.name), address: localized(data.address) } : null;
}

// Logic lives in handler.ts so it can be tested with `deno test` (handler_test.ts).
Deno.serve((req: Request) => handleShareWash(req, fetchBranch));
