-- Database clean-up after the 4 Nov review.
--
-- 1. branch_shares was a view over legacy_branch_shares running as its owner,
--    so anyone could insert through it past RLS. The customer app records
--    shares there, so it becomes the real table: anyone may add a share for an
--    existing branch (a signed-in customer only as themself); nobody reads it
--    from the apps.
-- 2. The other legacy_* tables are empty and unused; they go.
-- 3. reset_all_mock_data() is kept as it was, minus the dropped tables.
-- 4. Timeouts for the API role, so a crashed portal request cannot hold a
--    pooled connection or locks for good.

DROP VIEW public.branch_shares;
ALTER TABLE public.legacy_branch_shares RENAME TO branch_shares;
ALTER INDEX public.legacy_branch_shares_branch_id_idx RENAME TO branch_shares_branch_id_idx;
-- It pointed at legacy_branches; shares belong to the real branches.
ALTER TABLE public.branch_shares DROP CONSTRAINT branch_shares_branch_id_fkey;
ALTER TABLE public.branch_shares ADD CONSTRAINT branch_shares_branch_id_fkey
  FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;
ALTER TABLE public.branch_shares ENABLE ROW LEVEL SECURITY;
DROP POLICY "Allow public insert to branch_shares" ON public.branch_shares;
DROP POLICY "Allow public select to branch_shares" ON public.branch_shares;
REVOKE ALL ON public.branch_shares FROM anon, authenticated;
GRANT INSERT (branch_id, user_id, platform) ON public.branch_shares TO anon, authenticated;
CREATE POLICY "Guests record a share without a user" ON public.branch_shares
  FOR INSERT TO anon
  WITH CHECK (user_id IS NULL);
CREATE POLICY "Customers record a share as themselves" ON public.branch_shares
  FOR INSERT TO authenticated
  WITH CHECK (user_id IS NULL OR user_id IN (auth.uid()::text, (SELECT public.current_customer_id())));

DROP TABLE public.legacy_reviews, public.legacy_orders, public.legacy_complaints, public.legacy_favorites, public.legacy_notifications, public.legacy_offers, public.legacy_services, public.legacy_vehicles, public.legacy_branches, public.legacy_customers, public.legacy_areas, public.legacy_app_health;

CREATE OR REPLACE FUNCTION public.reset_all_mock_data()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  TRUNCATE TABLE
    public.order_events,
    public.order_notes,
    public.order_items,
    public.transactions,
    public.payments,
    public.payouts,
    public.day_closings,
    public.complaint_notes,
    public.complaints,
    public.reviews,
    public.customer_notifications,
    public.vendor_notifications,
    public.admin_notifications,
    public.customer_favorites,
    public.live_booking_devices,
    public.push_devices,
    public.orders,
    public.offer_branches,
    public.offer_categories,
    public.offers,
    public.branch_blocked_slots,
    public.branch_amenities,
    public.branch_photos,
    public.branch_working_hours,
    public.staff_shifts,
    public.staff_shift_patterns,
    public.staff,
    public.services,
    public.branches,
    public.business_settings,
    public.wash_applications,
    public.businesses,
    public.vehicles,
    public.customers,
    public.audit_logs,
    public.branch_shares
  CASCADE;
END;
$function$;

ALTER ROLE postgres SET idle_in_transaction_session_timeout = '60s';
ALTER ROLE postgres SET statement_timeout = '30s';
