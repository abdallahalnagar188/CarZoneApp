-- Migration: 20261028120000_push_devices_token_handover.sql
-- A push token belongs to a device, not to an account. When a phone signs in with a
-- different account, the app upserts its token (ON CONFLICT (token)), but the existing
-- row still belongs to the previous account, so the "own push devices" policy rejects
-- the update with 403 and the token stays on the old account: the new account gets no
-- push on that phone, and the old one keeps getting them.
--
-- This BEFORE INSERT trigger removes the row of the previous owner first, so the insert
-- goes through as a plain insert for the signed-in user. It runs before the policy's
-- WITH CHECK (user_id = auth.uid()), so a user can only claim a token for themselves;
-- if that check fails the whole statement, delete included, is rolled back.
-- Upserts by the same user still take the ON CONFLICT DO UPDATE path.

CREATE OR REPLACE FUNCTION public.push_devices_take_over_token()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $func$
BEGIN
  DELETE FROM public.push_devices
  WHERE token = NEW.token
    AND user_id IS DISTINCT FROM NEW.user_id;
  RETURN NEW;
END;
$func$;

REVOKE EXECUTE ON FUNCTION public.push_devices_take_over_token() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_push_devices_take_over_token ON public.push_devices;
CREATE TRIGGER trg_push_devices_take_over_token
BEFORE INSERT ON public.push_devices
FOR EACH ROW
EXECUTE FUNCTION public.push_devices_take_over_token();
