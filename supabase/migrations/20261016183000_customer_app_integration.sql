-- ============================================================================
-- Migration: 20261016183000_customer_app_integration.sql
-- Goal: Grant permissions, RLS policies, and sync RPC for Flutter Customer App
-- ============================================================================

-- 1. Helper function for RLS: get current customer id for authenticated user
CREATE OR REPLACE FUNCTION public.current_customer_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.customers WHERE user_id = (SELECT auth.uid()) LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.current_customer_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_customer_id() TO anon, authenticated;

-- 2. Schema USAGE
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- 3. Public catalog read access
GRANT SELECT ON public.areas TO anon, authenticated;
GRANT SELECT ON public.branches TO anon, authenticated;
GRANT SELECT ON public.branch_photos TO anon, authenticated;
GRANT SELECT ON public.branch_amenities TO anon, authenticated;
GRANT SELECT ON public.amenities TO anon, authenticated;
GRANT SELECT ON public.branch_working_hours TO anon, authenticated;
GRANT SELECT ON public.services TO anon, authenticated;
GRANT SELECT ON public.service_categories TO anon, authenticated;
GRANT SELECT ON public.offers TO anon, authenticated;
GRANT SELECT ON public.offer_branches TO anon, authenticated;
GRANT SELECT ON public.reviews TO anon, authenticated;

-- RLS Policies for Catalog
DROP POLICY IF EXISTS "Public read active areas" ON public.areas;
CREATE POLICY "Public read active areas" ON public.areas
  FOR SELECT TO anon, authenticated
  USING (active = true);

DROP POLICY IF EXISTS "Public read active branches" ON public.branches;
CREATE POLICY "Public read active branches" ON public.branches
  FOR SELECT TO anon, authenticated
  USING (active = true);

DROP POLICY IF EXISTS "Public read branch photos" ON public.branch_photos;
CREATE POLICY "Public read branch photos" ON public.branch_photos
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Public read branch amenities" ON public.branch_amenities;
CREATE POLICY "Public read branch amenities" ON public.branch_amenities
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Public read amenities" ON public.amenities;
CREATE POLICY "Public read amenities" ON public.amenities
  FOR SELECT TO anon, authenticated
  USING (active = true);

DROP POLICY IF EXISTS "Public read branch working hours" ON public.branch_working_hours;
CREATE POLICY "Public read branch working hours" ON public.branch_working_hours
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Public read active services" ON public.services;
CREATE POLICY "Public read active services" ON public.services
  FOR SELECT TO anon, authenticated
  USING (active = true);

DROP POLICY IF EXISTS "Public read active categories" ON public.service_categories;
CREATE POLICY "Public read active categories" ON public.service_categories
  FOR SELECT TO anon, authenticated
  USING (active = true);

DROP POLICY IF EXISTS "Public read active offers" ON public.offers;
CREATE POLICY "Public read active offers" ON public.offers
  FOR SELECT TO anon, authenticated
  USING (status = 'active');

DROP POLICY IF EXISTS "Public read offer branches" ON public.offer_branches;
CREATE POLICY "Public read offer branches" ON public.offer_branches
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Public read visible reviews" ON public.reviews;
CREATE POLICY "Public read visible reviews" ON public.reviews
  FOR SELECT TO anon, authenticated
  USING (status = 'visible');

-- 4. Customer Profile & Self Management
GRANT SELECT, INSERT, UPDATE ON public.customers TO authenticated;

DROP POLICY IF EXISTS "Customers can select own row" ON public.customers;
CREATE POLICY "Customers can select own row" ON public.customers
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Customers can insert own row" ON public.customers;
CREATE POLICY "Customers can insert own row" ON public.customers
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Customers can update own row" ON public.customers;
CREATE POLICY "Customers can update own row" ON public.customers
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- 5. Vehicles Management
GRANT SELECT, INSERT, UPDATE, DELETE ON public.vehicles TO authenticated;

DROP POLICY IF EXISTS "Customers can select own vehicles" ON public.vehicles;
CREATE POLICY "Customers can select own vehicles" ON public.vehicles
  FOR SELECT TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can insert own vehicles" ON public.vehicles;
CREATE POLICY "Customers can insert own vehicles" ON public.vehicles
  FOR INSERT TO authenticated
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can update own vehicles" ON public.vehicles;
CREATE POLICY "Customers can update own vehicles" ON public.vehicles
  FOR UPDATE TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()))
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can delete own vehicles" ON public.vehicles;
CREATE POLICY "Customers can delete own vehicles" ON public.vehicles
  FOR DELETE TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()));

-- 6. Orders, Items, and Events
GRANT SELECT, INSERT, UPDATE ON public.orders TO authenticated;
GRANT SELECT, INSERT ON public.order_items TO authenticated;
GRANT SELECT, INSERT ON public.order_events TO authenticated;

DROP POLICY IF EXISTS "Customers can select own orders" ON public.orders;
CREATE POLICY "Customers can select own orders" ON public.orders
  FOR SELECT TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can insert own orders" ON public.orders;
CREATE POLICY "Customers can insert own orders" ON public.orders
  FOR INSERT TO authenticated
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can update own orders" ON public.orders;
CREATE POLICY "Customers can update own orders" ON public.orders
  FOR UPDATE TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()))
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can select own order items" ON public.order_items;
CREATE POLICY "Customers can select own order items" ON public.order_items
  FOR SELECT TO authenticated
  USING (order_id IN (SELECT id FROM public.orders WHERE customer_id = (SELECT public.current_customer_id())));

DROP POLICY IF EXISTS "Customers can insert own order items" ON public.order_items;
CREATE POLICY "Customers can insert own order items" ON public.order_items
  FOR INSERT TO authenticated
  WITH CHECK (order_id IN (SELECT id FROM public.orders WHERE customer_id = (SELECT public.current_customer_id())));

DROP POLICY IF EXISTS "Customers can select own order events" ON public.order_events;
CREATE POLICY "Customers can select own order events" ON public.order_events
  FOR SELECT TO authenticated
  USING (order_id IN (SELECT id FROM public.orders WHERE customer_id = (SELECT public.current_customer_id())));

DROP POLICY IF EXISTS "Customers can insert own order events" ON public.order_events;
CREATE POLICY "Customers can insert own order events" ON public.order_events
  FOR INSERT TO authenticated
  WITH CHECK (order_id IN (SELECT id FROM public.orders WHERE customer_id = (SELECT public.current_customer_id())));

-- 7. Favorites
GRANT SELECT, INSERT, DELETE ON public.customer_favorites TO authenticated;

DROP POLICY IF EXISTS "Customers can select own favorites" ON public.customer_favorites;
CREATE POLICY "Customers can select own favorites" ON public.customer_favorites
  FOR SELECT TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can insert own favorites" ON public.customer_favorites;
CREATE POLICY "Customers can insert own favorites" ON public.customer_favorites
  FOR INSERT TO authenticated
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can delete own favorites" ON public.customer_favorites;
CREATE POLICY "Customers can delete own favorites" ON public.customer_favorites
  FOR DELETE TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()));

-- 8. Notifications
GRANT SELECT, UPDATE ON public.customer_notifications TO authenticated;

DROP POLICY IF EXISTS "Customers can select own notifications" ON public.customer_notifications;
CREATE POLICY "Customers can select own notifications" ON public.customer_notifications
  FOR SELECT TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can mark own notifications read" ON public.customer_notifications;
CREATE POLICY "Customers can mark own notifications read" ON public.customer_notifications
  FOR UPDATE TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()))
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

-- 9. Reviews (Customers can create review for their order)
GRANT INSERT, UPDATE ON public.reviews TO authenticated;

DROP POLICY IF EXISTS "Customers can insert review" ON public.reviews;
CREATE POLICY "Customers can insert review" ON public.reviews
  FOR INSERT TO authenticated
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can update own review" ON public.reviews;
CREATE POLICY "Customers can update own review" ON public.reviews
  FOR UPDATE TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()))
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

-- 10. Complaints
GRANT SELECT, INSERT ON public.complaints TO authenticated;

DROP POLICY IF EXISTS "Customers can select own complaints" ON public.complaints;
CREATE POLICY "Customers can select own complaints" ON public.complaints
  FOR SELECT TO authenticated
  USING (customer_id = (SELECT public.current_customer_id()));

DROP POLICY IF EXISTS "Customers can insert own complaints" ON public.complaints;
CREATE POLICY "Customers can insert own complaints" ON public.complaints
  FOR INSERT TO authenticated
  WITH CHECK (customer_id = (SELECT public.current_customer_id()));

-- 11. Push Devices (Tokens)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.push_devices TO authenticated;

DROP POLICY IF EXISTS "Users can manage own push devices" ON public.push_devices;
CREATE POLICY "Users can manage own push devices" ON public.push_devices
  FOR ALL TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- 12. Compatibility Views & Analytics
CREATE OR REPLACE VIEW public.app_health AS
SELECT 1 AS id, 'healthy' AS status, now() AS updated_at;
GRANT SELECT ON public.app_health TO anon, authenticated;

CREATE OR REPLACE VIEW public.branch_shares AS
SELECT * FROM public.legacy_branch_shares;
GRANT SELECT, INSERT ON public.branch_shares TO anon, authenticated;

-- 13. Customer Profile Sync / Registration RPC Function
CREATE OR REPLACE FUNCTION public.sync_customer_profile(
  p_phone text,
  p_name text DEFAULT NULL,
  p_locale text DEFAULT 'ar'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_cust public.customers%ROWTYPE;
  v_clean_phone text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Normalize phone to E.164 (strip whitespace)
  v_clean_phone := regexp_replace(p_phone, '\s+', '', 'g');

  -- 1. Try to find by user_id
  SELECT * INTO v_cust FROM public.customers WHERE user_id = v_uid LIMIT 1;

  IF FOUND THEN
    UPDATE public.customers
    SET 
      name = CASE WHEN p_name IS NOT NULL AND length(trim(p_name)) >= 2 THEN trim(p_name) ELSE name END,
      locale = COALESCE(p_locale, locale),
      last_active_at = now(),
      updated_at = now()
    WHERE id = v_cust.id
    RETURNING * INTO v_cust;

    RETURN to_jsonb(v_cust);
  END IF;

  -- 2. Try to find by phone (e.g. seeded demo user or unlinked record)
  SELECT * INTO v_cust FROM public.customers WHERE phone = v_clean_phone LIMIT 1;

  IF FOUND THEN
    -- Link existing record to current auth.uid()
    UPDATE public.customers
    SET 
      user_id = v_uid,
      name = CASE WHEN p_name IS NOT NULL AND length(trim(p_name)) >= 2 THEN trim(p_name) ELSE name END,
      locale = COALESCE(p_locale, locale),
      last_active_at = now(),
      updated_at = now()
    WHERE id = v_cust.id
    RETURNING * INTO v_cust;

    RETURN to_jsonb(v_cust);
  END IF;

  -- 3. If neither found, create a new record if name is provided
  IF p_name IS NOT NULL AND length(trim(p_name)) >= 2 THEN
    INSERT INTO public.customers (
      id,
      user_id,
      name,
      phone,
      locale,
      status,
      last_active_at
    ) VALUES (
      public.gen_id('cu'),
      v_uid,
      trim(p_name),
      v_clean_phone,
      COALESCE(p_locale, 'ar'),
      'active',
      now()
    )
    RETURNING * INTO v_cust;

    RETURN to_jsonb(v_cust);
  END IF;

  RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_customer_profile(text, text, text) TO authenticated;

-- 14. Essential Functions & Sequences Grants for Column Defaults
GRANT EXECUTE ON FUNCTION public.gen_id(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.gen_check_in_code() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.normalize_plate(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_localized(jsonb) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.next_order_number(order_source) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.next_complaint_ticket() TO anon, authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
