import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { handleSendSms } from "./handler.ts";

// Logic lives in handler.ts so it can be tested with `deno test` (handler_test.ts).
Deno.serve((req: Request) => handleSendSms(req));
