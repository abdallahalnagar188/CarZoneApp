# send-push

Sends every new `public.customer_notifications` row to the customer's phones over FCM HTTP v1.
Called by the `trg_customer_notifications_send_push` trigger
(`supabase/migrations/20261020150000_customer_notifications_send_push.sql`) through `pg_net`.

## Secrets

Stored in Vault (the CLI account cannot set Edge Function secrets). The function reads the first two
through `public.send_push_config()` (service_role only); Edge Function secrets with the env names below win if set.

| Vault name | Env name | Value |
|---|---|---|
| `firebase_service_account` | `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON for `chatapp-188` (Firebase console → Project settings → Service accounts → Generate new private key). Raw JSON or base64. |
| `send_push_webhook_secret` | `PUSH_WEBHOOK_SECRET` | Random string. The trigger sends it in `x-webhook-secret`; the function rejects requests without it. |
| `send_push_url` | — | `https://<project-ref>.supabase.co/functions/v1/send-push` (used by the trigger) |

iOS delivery also needs the APNs auth key uploaded in Firebase console → Project settings → Cloud Messaging.

## Setup

```bash
supabase functions deploy send-push --no-verify-jwt
supabase db query --linked -f supabase/migrations/20261020150000_customer_notifications_send_push.sql
```

Then store the three Vault secrets from a SQL file outside the repo (do not commit the values), e.g.
`select vault.create_secret($sa$<json>$sa$, 'firebase_service_account');`
Until `send_push_url` and `send_push_webhook_secret` exist the trigger does nothing; until
`firebase_service_account` exists the function answers 500 "FCM is not configured".

## Tests

```bash
deno test supabase/functions/send-push/handler_test.ts
```

Delivery results: Edge Function logs (`[send-push] <id>: sent …`) and `net._http_response`.
