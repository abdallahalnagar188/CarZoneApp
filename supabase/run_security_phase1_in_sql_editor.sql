-- ============================================================================
-- شغّل الملف ده مرة واحدة من Supabase Dashboard -> SQL Editor -> Run
-- Run once from Supabase Dashboard -> SQL Editor -> Run.
--
-- ده نفس supabase/migrations/20261019120000_security_phase1.sql بالظبط،
-- جوه transaction: لو أي سطر فشل، مفيش أي حاجة بتتطبق.
-- Same as the migration file, inside one transaction: all or nothing.
-- آمن لو اتشغل أكتر من مرة. Safe to re-run.
--
-- النتيجة المتوقعة في الآخر: 3 صفوف create_order / cancel_order / reschedule_order
-- Expected result at the end: 3 rows (create_order, cancel_order, reschedule_order).
-- ============================================================================

BEGIN;

-- ============================================================================
-- Migration: 20261019120000_security_phase1.sql
-- QA security phase 1 (docs/qa/QA_REPORT.md):
--   C1  sync_customer_profile linked any customer row by an unverified phone
--       -> link only through the phone Supabase Auth verified; customers can no
--          longer insert their own row or change phone/status/user_id directly.
--   C3  customers could rewrite any order column (total, status, payment)
--       -> customers write orders only through create_order / cancel_order /
--          reschedule_order, which price, validate and number the order on the
--          server. Staff and admins keep their existing direct access.
--   C4  order numbers are now assigned by next_order_number() on the server.
-- Safe to re-run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Role helpers
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.staff s WHERE s.user_id = (SELECT auth.uid()))
      OR EXISTS (SELECT 1 FROM public.admin_users a WHERE a.user_id = (SELECT auth.uid()));
$$;

REVOKE ALL ON FUNCTION public.is_staff_or_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_staff_or_admin() TO authenticated;

-- Phone numbers compared as digits only: customers store '+2010…', auth.users stores '2010…'.
CREATE INDEX IF NOT EXISTS idx_customers_phone_digits
  ON public.customers (regexp_replace(phone, '\D', '', 'g'));

-- ----------------------------------------------------------------------------
-- 2. C1: sync_customer_profile trusts only the verified auth phone
-- ----------------------------------------------------------------------------
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
  v_verified text;
  v_input text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
  v_phone text;
  v_name text := nullif(trim(coalesce(p_name, '')), '');
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF v_name IS NOT NULL AND length(v_name) < 2 THEN
    v_name := NULL;
  END IF;

  -- 1. Already linked: refresh profile fields only (never phone or owner).
  SELECT * INTO v_cust FROM public.customers WHERE user_id = v_uid LIMIT 1;
  IF FOUND THEN
    UPDATE public.customers
    SET name = coalesce(v_name, name),
        locale = coalesce(p_locale, locale),
        last_active_at = now(),
        updated_at = now()
    WHERE id = v_cust.id
    RETURNING * INTO v_cust;
    RETURN to_jsonb(v_cust);
  END IF;

  -- The only phone we trust is the one Supabase Auth verified by OTP.
  SELECT nullif(regexp_replace(coalesce(u.phone, ''), '\D', '', 'g'), '')
    INTO v_verified
  FROM auth.users u
  WHERE u.id = v_uid;

  IF v_verified IS NOT NULL THEN
    -- 2. Verified phone: claim an existing unlinked row (e.g. walk-in or seeded customer).
    SELECT * INTO v_cust
    FROM public.customers
    WHERE regexp_replace(phone, '\D', '', 'g') = v_verified
    ORDER BY (user_id IS NULL) DESC, created_at
    LIMIT 1
    FOR UPDATE;

    IF FOUND THEN
      IF v_cust.user_id IS NOT NULL THEN
        RAISE EXCEPTION 'phone_in_use';
      END IF;
      UPDATE public.customers
      SET user_id = v_uid,
          name = coalesce(v_name, name),
          locale = coalesce(p_locale, locale),
          last_active_at = now(),
          updated_at = now()
      WHERE id = v_cust.id
      RETURNING * INTO v_cust;
      RETURN to_jsonb(v_cust);
    END IF;
    v_phone := '+' || v_verified;
  ELSE
    -- 3. No verified phone (e.g. Google sign-in): never link by phone, and do not
    --    let an unverified number shadow an existing customer.
    IF v_input = '' THEN
      RAISE EXCEPTION 'phone_required';
    END IF;
    IF EXISTS (SELECT 1 FROM public.customers WHERE regexp_replace(phone, '\D', '', 'g') = v_input) THEN
      RAISE EXCEPTION 'phone_in_use';
    END IF;
    v_phone := '+' || v_input;
  END IF;

  -- 4. Create a new customer once we have a name.
  IF v_name IS NULL THEN
    RETURN NULL;
  END IF;

  INSERT INTO public.customers (id, user_id, name, phone, locale, status, last_active_at)
  VALUES (public.gen_id('cu'), v_uid, v_name, v_phone, coalesce(p_locale, 'ar'), 'active', now())
  RETURNING * INTO v_cust;

  RETURN to_jsonb(v_cust);
END;
$$;

REVOKE ALL ON FUNCTION public.sync_customer_profile(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sync_customer_profile(text, text, text) TO authenticated;

-- Customers are created only through sync_customer_profile.
DROP POLICY IF EXISTS "Customers can insert own row" ON public.customers;

-- A customer may edit their name/locale, never phone, status or owner.
CREATE OR REPLACE FUNCTION public.guard_customer_self_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- Only direct API calls are limited; SECURITY DEFINER functions run as their owner.
  IF current_user IN ('authenticated', 'anon') AND NOT public.is_staff_or_admin() THEN
    IF NEW.phone IS DISTINCT FROM OLD.phone
       OR NEW.status IS DISTINCT FROM OLD.status
       OR NEW.status_reason IS DISTINCT FROM OLD.status_reason
       OR NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'customer_field_locked' USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_customer_self_update ON public.customers;
CREATE TRIGGER trg_guard_customer_self_update
BEFORE UPDATE ON public.customers
FOR EACH ROW EXECUTE FUNCTION public.guard_customer_self_update();

-- ----------------------------------------------------------------------------
-- 3. C3: customers never write orders directly
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Customers can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Customers can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Customer insert orders" ON public.orders;
DROP POLICY IF EXISTS "Customers can insert own order items" ON public.order_items;
DROP POLICY IF EXISTS "Customers can insert own order events" ON public.order_events;

-- RESTRICTIVE policies are ANDed with every permissive one, so no leftover
-- policy can re-open direct writes to customers. Staff and admins are unaffected.
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['orders', 'order_items', 'order_events'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Writes only by staff or admin (insert)" ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Writes only by staff or admin (update)" ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS "Writes only by staff or admin (delete)" ON public.%I', t);
    EXECUTE format('CREATE POLICY "Writes only by staff or admin (insert)" ON public.%I AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_staff_or_admin()))', t);
    EXECUTE format('CREATE POLICY "Writes only by staff or admin (update)" ON public.%I AS RESTRICTIVE FOR UPDATE TO authenticated USING ((SELECT public.is_staff_or_admin())) WITH CHECK ((SELECT public.is_staff_or_admin()))', t);
    EXECUTE format('CREATE POLICY "Writes only by staff or admin (delete)" ON public.%I AS RESTRICTIVE FOR DELETE TO authenticated USING ((SELECT public.is_staff_or_admin()))', t);
    EXECUTE format('REVOKE INSERT, UPDATE, DELETE ON public.%I FROM anon', t);
  END LOOP;
END $$;

-- ----------------------------------------------------------------------------
-- 4. Booking RPCs (the only way a customer creates or changes an order)
-- ----------------------------------------------------------------------------

-- Current customer for the caller, or an error the app can map.
CREATE OR REPLACE FUNCTION public._booking_customer()
RETURNS public.customers
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cust public.customers%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;
  SELECT * INTO v_cust FROM public.customers WHERE user_id = auth.uid() LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'customer_not_found';
  END IF;
  IF v_cust.status <> 'active' THEN
    RAISE EXCEPTION 'account_suspended';
  END IF;
  RETURN v_cust;
END;
$$;

-- Raises unless [p_start, p_start + p_duration) is bookable at the branch.
-- Times are judged in Africa/Cairo. Call while holding the branch lock.
CREATE OR REPLACE FUNCTION public._assert_slot_bookable(
  p_branch public.branches,
  p_start timestamptz,
  p_duration int,
  p_exclude_order text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_local timestamp := p_start AT TIME ZONE 'Africa/Cairo';
  v_end timestamptz := p_start + make_interval(mins => p_duration);
  v_hours public.branch_working_hours%ROWTYPE;
  v_open int;
  v_close int;
  v_start_min int;
  v_used int;
BEGIN
  IF p_start < now() + make_interval(mins => p_branch.lead_time_min) THEN
    RAISE EXCEPTION 'slot_too_soon';
  END IF;
  IF v_local::date > (now() AT TIME ZONE 'Africa/Cairo')::date + p_branch.max_advance_days THEN
    RAISE EXCEPTION 'slot_too_far';
  END IF;

  SELECT * INTO v_hours
  FROM public.branch_working_hours
  WHERE branch_id = p_branch.id AND weekday = extract(dow FROM v_local)::int;
  IF NOT FOUND OR v_hours.closed THEN
    RAISE EXCEPTION 'slot_outside_hours';
  END IF;

  v_open := extract(hour FROM v_hours.opens_at)::int * 60 + extract(minute FROM v_hours.opens_at)::int;
  v_close := extract(hour FROM v_hours.closes_at)::int * 60 + extract(minute FROM v_hours.closes_at)::int;
  IF v_close <= v_open THEN
    v_close := v_close + 1440; -- closes at or after midnight
  END IF;
  v_start_min := extract(hour FROM v_local)::int * 60 + extract(minute FROM v_local)::int;

  IF extract(second FROM v_local) <> 0
     OR v_start_min < v_open
     OR v_start_min + p_duration > v_close
     OR (v_start_min - v_open) % greatest(p_branch.slot_interval_min, 1) <> 0 THEN
    RAISE EXCEPTION 'slot_outside_hours';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.branch_blocked_slots b
    WHERE b.branch_id = p_branch.id AND b.starts_at < v_end AND b.ends_at > p_start
  ) THEN
    RAISE EXCEPTION 'slot_unavailable';
  END IF;

  SELECT count(*) INTO v_used
  FROM public.orders o
  WHERE o.branch_id = p_branch.id
    AND o.status IN ('pending', 'confirmed', 'waiting', 'in_service')
    AND o.id IS DISTINCT FROM p_exclude_order
    AND o.scheduled_at < v_end
    AND o.scheduled_at + make_interval(mins => o.duration_min) > p_start;

  IF v_used >= p_branch.capacity THEN
    RAISE EXCEPTION 'slot_unavailable';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public._booking_customer() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._assert_slot_bookable(public.branches, timestamptz, int, text) FROM PUBLIC, anon, authenticated;

-- Order row + items + events, in the shape OrderModel.fromJson reads.
CREATE OR REPLACE FUNCTION public._order_json(p_order_id text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT to_jsonb(o)
    || jsonb_build_object(
         'order_items', coalesce((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.position) FROM public.order_items i WHERE i.order_id = o.id), '[]'::jsonb),
         'order_events', coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY e.at) FROM public.order_events e WHERE e.order_id = o.id), '[]'::jsonb)
       )
  FROM public.orders o
  WHERE o.id = p_order_id;
$$;

REVOKE ALL ON FUNCTION public._order_json(text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_order(
  p_branch_id text,
  p_vehicle_id text,
  p_primary_service_id text,
  p_scheduled_at timestamptz,
  p_addon_service_ids text[] DEFAULT '{}'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cust public.customers := public._booking_customer();
  v_branch public.branches%ROWTYPE;
  v_vehicle public.vehicles%ROWTYPE;
  v_primary public.services%ROWTYPE;
  v_addons public.services[];
  v_addon_ids text[] := ARRAY(SELECT DISTINCT unnest(coalesce(p_addon_service_ids, '{}')));
  v_subtotal numeric;
  v_duration int;
  v_offer_id text;
  v_offer_type public.discount_type;
  v_offer_value numeric;
  v_discount numeric := 0;
  v_order public.orders%ROWTYPE;
  v_status public.order_status;
BEGIN
  SELECT b.* INTO v_branch
  FROM public.branches b
  JOIN public.businesses biz ON biz.id = b.business_id
  WHERE b.id = p_branch_id AND b.active AND biz.status IN ('active', 'approved');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'branch_unavailable';
  END IF;

  SELECT * INTO v_vehicle FROM public.vehicles WHERE id = p_vehicle_id AND customer_id = v_cust.id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'vehicle_not_found';
  END IF;

  SELECT * INTO v_primary
  FROM public.services
  WHERE id = p_primary_service_id AND branch_id = v_branch.id AND type = 'primary' AND active;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'service_not_found';
  END IF;

  SELECT coalesce(array_agg(s ORDER BY array_position(v_addon_ids, s.id)), '{}') INTO v_addons
  FROM public.services s
  WHERE s.id = ANY (v_addon_ids) AND s.branch_id = v_branch.id AND s.type = 'addon' AND s.active;
  IF cardinality(v_addons) <> cardinality(v_addon_ids) THEN
    RAISE EXCEPTION 'invalid_addon';
  END IF;

  SELECT v_primary.price + coalesce(sum(a.price), 0),
         v_primary.duration_min + coalesce(sum(a.duration_min), 0)::int
    INTO v_subtotal, v_duration
  FROM unnest(v_addons) AS a;

  -- Best live offer for this branch; applies to the primary service only.
  -- An offer with no categories covers every service.
  SELECT o.id, o.discount_type, o.discount_value,
         CASE WHEN o.discount_type = 'percent'
              THEN round(v_primary.price * o.discount_value / 100.0)
              ELSE least(o.discount_value, v_primary.price) END AS amount
    INTO v_offer_id, v_offer_type, v_offer_value, v_discount
  FROM public.offers o
  JOIN public.offer_branches ob ON ob.offer_id = o.id AND ob.branch_id = v_branch.id
  WHERE o.status = 'active'
    AND now() >= o.starts_at AND now() < o.ends_at
    AND (NOT EXISTS (SELECT 1 FROM public.offer_categories oc WHERE oc.offer_id = o.id)
         OR EXISTS (SELECT 1 FROM public.offer_categories oc WHERE oc.offer_id = o.id AND oc.category_id = v_primary.category_id))
  ORDER BY amount DESC, o.id
  LIMIT 1;
  v_discount := greatest(coalesce(v_discount, 0), 0);

  -- Serialize bookings per branch so two customers cannot take the last seat.
  PERFORM pg_advisory_xact_lock(hashtext('carzone_slot:' || v_branch.id));
  PERFORM public._assert_slot_bookable(v_branch, p_scheduled_at, v_duration);

  v_status := CASE WHEN v_branch.auto_confirm THEN 'confirmed' ELSE 'pending' END;

  INSERT INTO public.orders (
    number, source, customer_id, vehicle_id, plate, business_id, branch_id,
    offer_id, subtotal, discount_amount, discount_pct, discount_reason, total,
    duration_min, scheduled_at, status, payment_status
  ) VALUES (
    public.next_order_number('app'), 'app', v_cust.id, v_vehicle.id, v_vehicle.plate,
    v_branch.business_id, v_branch.id,
    CASE WHEN v_discount > 0 THEN v_offer_id END,
    v_subtotal,
    CASE WHEN v_discount > 0 THEN v_discount END,
    CASE WHEN v_discount > 0 AND v_offer_type = 'percent' THEN v_offer_value END,
    CASE WHEN v_discount > 0 THEN 'offer' END,
    v_subtotal - v_discount,
    v_duration, p_scheduled_at, v_status, 'pending'
  )
  RETURNING * INTO v_order;

  INSERT INTO public.order_items (order_id, service_id, name, type, price, duration_min, position)
  SELECT v_order.id, s.id, s.name, s.type, s.price, s.duration_min, s.pos
  FROM (
    SELECT v_primary.id, v_primary.name, v_primary.type, v_primary.price, v_primary.duration_min, 0 AS pos
    UNION ALL
    SELECT t.id, t.name, t.type, t.price, t.duration_min, t.ordinality::int
    FROM unnest(v_addons) WITH ORDINALITY AS t
  ) AS s(id, name, type, price, duration_min, pos);

  INSERT INTO public.order_events (order_id, status, actor_type, actor_id)
  VALUES (v_order.id, 'pending', 'customer', v_cust.id);
  IF v_status = 'confirmed' THEN
    INSERT INTO public.order_events (order_id, status, actor_type, actor_id)
    VALUES (v_order.id, 'confirmed', 'system', 'auto_confirm');
  END IF;

  RETURN public._order_json(v_order.id);
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_order(p_order_id text, p_reason text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cust public.customers := public._booking_customer();
  v_order public.orders%ROWTYPE;
  v_free_min int;
  v_late boolean;
BEGIN
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND customer_id = v_cust.id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'order_not_found';
  END IF;
  IF v_order.status NOT IN ('pending', 'confirmed') THEN
    RAISE EXCEPTION 'order_not_cancellable';
  END IF;

  SELECT free_cancel_min INTO v_free_min FROM public.branches WHERE id = v_order.branch_id;
  v_late := v_order.scheduled_at - now() < make_interval(mins => coalesce(v_free_min, 60));

  UPDATE public.orders
  SET status = 'cancelled',
      cancel_reason = left(coalesce(nullif(trim(p_reason), ''), 'Cancelled by customer'), 500),
      cancelled_at = now(),
      cancelled_by_type = 'customer',
      cancelled_by_id = v_cust.id,
      updated_at = now()
  WHERE id = v_order.id;

  INSERT INTO public.order_events (order_id, status, actor_type, actor_id)
  VALUES (v_order.id, 'cancelled', 'customer', v_cust.id);

  RETURN public._order_json(v_order.id) || jsonb_build_object('late_cancel', v_late);
END;
$$;

CREATE OR REPLACE FUNCTION public.reschedule_order(p_order_id text, p_scheduled_at timestamptz)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cust public.customers := public._booking_customer();
  v_order public.orders%ROWTYPE;
  v_branch public.branches%ROWTYPE;
BEGIN
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND customer_id = v_cust.id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'order_not_found';
  END IF;
  IF v_order.status NOT IN ('pending', 'confirmed') THEN
    RAISE EXCEPTION 'order_not_reschedulable';
  END IF;

  SELECT * INTO v_branch FROM public.branches WHERE id = v_order.branch_id;
  PERFORM pg_advisory_xact_lock(hashtext('carzone_slot:' || v_branch.id));
  PERFORM public._assert_slot_bookable(v_branch, p_scheduled_at, v_order.duration_min, v_order.id);

  UPDATE public.orders SET scheduled_at = p_scheduled_at, updated_at = now() WHERE id = v_order.id;

  RETURN public._order_json(v_order.id);
END;
$$;

REVOKE ALL ON FUNCTION public.create_order(text, text, text, timestamptz, text[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.cancel_order(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.reschedule_order(text, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_order(text, text, text, timestamptz, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_order(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reschedule_order(text, timestamptz) TO authenticated;

-- Logged-out clients never need the number generators (staff panels keep them).
REVOKE EXECUTE ON FUNCTION public.next_order_number(order_source) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.next_complaint_ticket() FROM PUBLIC, anon;

-- Let the API (PostgREST) see the new functions right away.
NOTIFY pgrst, 'reload schema';

COMMIT;

-- ---------------------------------------------------------------------------
-- Verification: must return 3 rows.
-- ---------------------------------------------------------------------------
SELECT p.proname AS function_name,
       pg_get_function_identity_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('create_order', 'cancel_order', 'reschedule_order')
ORDER BY 1;
