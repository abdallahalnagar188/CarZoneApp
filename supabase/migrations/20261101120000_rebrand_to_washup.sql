-- Migration: 20261101120000_rebrand_to_washup.sql
-- The product is Wash Up (واش أب). Removes the old CarZone / Carzen names from what
-- customers and washes read, and from the internal slot lock keys.
--
-- 1. Terms, privacy text and notification templates in platform settings.
-- 2. create_order / reschedule_order: advisory lock keys. Both functions are rewritten
--    in this one transaction, so they never lock on different keys.
--
-- clean_demo_auth_users keeps '@carzen.demo': it matches the real emails of the demo
-- accounts, so changing the text would stop it finding them.

UPDATE public.platform_settings
SET value = replace(replace(value::text, 'كارزن', 'واش أب'), 'Carzen', 'Wash Up')::jsonb,
    updated_at = now()
WHERE key IN ('legal', 'notification_templates');

DO $migration$
DECLARE
  v_def text;
BEGIN
  FOR v_def IN
    SELECT pg_get_functiondef(p.oid)
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname IN ('create_order', 'reschedule_order')
  LOOP
    EXECUTE replace(replace(v_def, 'carzone_slot:', 'washup_slot:'), 'carzone_customer:', 'washup_customer:');
  END LOOP;
END
$migration$;
