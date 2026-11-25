-- NOT APPLIED — to be reviewed and applied by the lead
--
-- GAP-036: the app's Settings → "Booking reminders" / "Offers" switches were stored on the
-- phone only and read by nothing. This adds where to keep them on the customer row; the app
-- writes them (customers UPDATE is already allowed on the own row, and guard_customer_row()
-- from 20261021090000 only pins id/user_id/phone/status/created_at), and send-push skips the
-- push (not the in-app notification) of a reminder or offer the customer turned off
-- (supabase/functions/send-push/handler.ts optedOut(); redeploy send-push after this).
--
-- Language: customers.locale already exists and is now updated by the app whenever the
-- customer switches language, so pushes follow the app language (no schema change needed).
--
-- Defaults keep today's behaviour (everything on). The app ignores the columns while they do
-- not exist, and send-push falls back to its old query, so the order of deployment is free.
--
-- Idempotent.

alter table public.customers
  add column if not exists notify_reminders boolean not null default true,
  add column if not exists notify_offers boolean not null default true;

comment on column public.customers.notify_reminders is
  'Customer setting: push reminders (booking_reminder, review_reminder, reminder). The in-app notification is still created.';
comment on column public.customers.notify_offers is
  'Customer setting: push offer notifications (type offer). The in-app notification is still created.';

-- In case UPDATE on customers is granted per column on the live database (harmless when the
-- role already has table-wide UPDATE). Row access stays with the existing RLS policies.
grant update (notify_reminders, notify_offers, locale) on public.customers to authenticated;
