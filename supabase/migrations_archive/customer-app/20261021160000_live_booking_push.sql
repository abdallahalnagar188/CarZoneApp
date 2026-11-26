-- Migration: 20261021160000_live_booking_push.sql
-- Live booking widget while the app is closed: when a wash changes an order's
-- status, the send-push Edge Function pushes the new stage straight to the
-- widget (iOS Live Activity push, Android data message), so it no longer waits
-- for the app to be opened.
--
-- live_booking_devices: a device showing the live widget for an order. The app
-- adds a row when it starts showing an order and removes it when it stops; the
-- function removes rows once the order is finished or a token is dead.
-- Uses the same Vault secrets as 20261020150000 (send_push_url, send_push_webhook_secret).

CREATE TABLE IF NOT EXISTS public.live_booking_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id text NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),
  fcm_token text NOT NULL,
  -- iOS only: the ActivityKit push token of the Live Activity.
  activity_token text,
  locale text NOT NULL DEFAULT 'ar' CHECK (locale IN ('ar', 'en')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (order_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS live_booking_devices_user_id_idx ON public.live_booking_devices (user_id);

ALTER TABLE public.live_booking_devices ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.live_booking_devices TO authenticated;

-- A customer may only follow their own orders.
DROP POLICY IF EXISTS "Customers manage own live booking devices" ON public.live_booking_devices;
CREATE POLICY "Customers manage own live booking devices" ON public.live_booking_devices
  FOR ALL TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id AND o.customer_id = (SELECT public.current_customer_id())
    )
  );

CREATE OR REPLACE FUNCTION public.notify_order_live_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $func$
DECLARE
  v_url text;
  v_secret text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.live_booking_devices WHERE order_id = NEW.id) THEN
    RETURN NULL;
  END IF;
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
      'record', jsonb_build_object('id', NEW.id, 'status', NEW.status),
      'old_record', jsonb_build_object('id', OLD.id, 'status', OLD.status)
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', v_secret
    ),
    timeout_milliseconds := 10000
  );
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  -- A push problem must never roll back the status change itself.
  RAISE WARNING 'live booking push for % failed: %', NEW.id, SQLERRM;
  RETURN NULL;
END;
$func$;

REVOKE EXECUTE ON FUNCTION public.notify_order_live_push() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_orders_live_push ON public.orders;
CREATE TRIGGER trg_orders_live_push
AFTER UPDATE OF status ON public.orders
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.notify_order_live_push();
