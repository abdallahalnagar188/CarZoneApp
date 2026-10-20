-- Migration: 20261020150000_customer_notifications_send_push.sql
-- Push delivery: every new row in public.customer_notifications is POSTed to the
-- send-push Edge Function (Database Webhook payload), which sends it over FCM to
-- the customer's devices in push_devices.
--
-- Needs two Vault secrets (set once per project, never committed):
--   send_push_url             https://<project-ref>.supabase.co/functions/v1/send-push
--   send_push_webhook_secret  same value as the PUSH_WEBHOOK_SECRET function secret
-- Until both exist the trigger does nothing, so inserts are never blocked.
-- pg_net is asynchronous: a slow or failing function never delays or fails the insert.

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.notify_customer_notification_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $func$
DECLARE
  v_url text;
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_url FROM vault.decrypted_secrets WHERE name = 'send_push_url';
  SELECT decrypted_secret INTO v_secret FROM vault.decrypted_secrets WHERE name = 'send_push_webhook_secret';
  IF v_url IS NULL OR v_secret IS NULL THEN
    RETURN NULL;
  END IF;

  PERFORM net.http_post(
    url := v_url,
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(NEW),
      'old_record', NULL
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', v_secret
    ),
    timeout_milliseconds := 10000
  );
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  -- A push problem must never roll back the notification itself.
  RAISE WARNING 'send-push webhook for % failed: %', NEW.id, SQLERRM;
  RETURN NULL;
END;
$func$;

REVOKE EXECUTE ON FUNCTION public.notify_customer_notification_push() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_customer_notifications_send_push ON public.customer_notifications;
CREATE TRIGGER trg_customer_notifications_send_push
AFTER INSERT ON public.customer_notifications
FOR EACH ROW
EXECUTE FUNCTION public.notify_customer_notification_push();
