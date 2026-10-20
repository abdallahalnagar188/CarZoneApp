# send-push

Sends every new `public.customer_notifications` row to the customer's phones over FCM HTTP v1.
Called by the `trg_customer_notifications_send_push` trigger
(`supabase/migrations/20261020150000_customer_notifications_send_push.sql`) through `pg_net`.

## Secrets

| Where | Name | Value |
|---|---|---|
| Function secret | `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON (Firebase console → Project settings → Service accounts → Generate new private key). Raw JSON or base64. |
| Function secret | `PUSH_WEBHOOK_SECRET` | Random string; the function rejects requests without it in `x-webhook-secret`. |
| Vault | `send_push_webhook_secret` | Same value as `PUSH_WEBHOOK_SECRET`. |
| Vault | `send_push_url` | `https://<project-ref>.supabase.co/functions/v1/send-push` |

iOS delivery also needs the APNs auth key uploaded in Firebase console → Project settings → Cloud Messaging.

## Setup

```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)" PUSH_WEBHOOK_SECRET=<secret>
supabase functions deploy send-push --no-verify-jwt
supabase db query --linked -f supabase/migrations/20261020150000_customer_notifications_send_push.sql
```

Then, in the SQL editor (do not commit the values):

```sql
select vault.create_secret('https://<project-ref>.supabase.co/functions/v1/send-push', 'send_push_url');
select vault.create_secret('<secret>', 'send_push_webhook_secret');
```

Until both Vault secrets exist the trigger does nothing.

## Tests

```bash
deno test supabase/functions/send-push/handler_test.ts
```

Delivery results: Edge Function logs (`[send-push] <id>: sent …`) and `net._http_response`.
