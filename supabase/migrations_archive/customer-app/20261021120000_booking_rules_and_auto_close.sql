-- Booking rules for customers, and auto-closing bookings whose time passed.
--
-- 1. A car can't have two overlapping active bookings (any branch): 'vehicle_busy'.
-- 2. A customer can hold at most 3 upcoming active bookings: 'too_many_bookings'.
-- 3. Every 10 minutes, bookings the wash never acted on are closed:
--    pending 30 min after the slot started -> cancelled (system, expired_unconfirmed)
--    confirmed 60 min after the slot ended -> no_show
--    (waiting / in_service are left to the wash: the car is physically there.)

CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION public._assert_customer_can_book(
  p_customer_id text,
  p_vehicle_id text,
  p_start timestamptz,
  p_duration integer,
  p_exclude_order text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.vehicle_id = p_vehicle_id
      AND o.id IS DISTINCT FROM p_exclude_order
      AND o.status IN ('pending', 'confirmed', 'waiting', 'in_service')
      AND o.scheduled_at < p_start + make_interval(mins => p_duration)
      AND o.scheduled_at + make_interval(mins => o.duration_min) > p_start
  ) THEN
    RAISE EXCEPTION 'vehicle_busy';
  END IF;

  -- Rescheduling keeps the count unchanged, so only new bookings are capped.
  IF p_exclude_order IS NULL AND (
    SELECT count(*) FROM public.orders o
    WHERE o.customer_id = p_customer_id
      AND o.status IN ('pending', 'confirmed', 'waiting', 'in_service')
      AND o.scheduled_at + make_interval(mins => o.duration_min) > now()
  ) >= 3 THEN
    RAISE EXCEPTION 'too_many_bookings';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public._assert_customer_can_book(text, text, timestamptz, integer, text) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_order(p_branch_id text, p_vehicle_id text, p_primary_service_id text, p_scheduled_at timestamp with time zone, p_addon_service_ids text[] DEFAULT '{}'::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  -- One booking per car at a time, at most 3 upcoming per customer.
  PERFORM pg_advisory_xact_lock(hashtext('carzone_customer:' || v_cust.id));
  PERFORM public._assert_customer_can_book(v_cust.id, v_vehicle.id, p_scheduled_at, v_duration);

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
$function$;

CREATE OR REPLACE FUNCTION public.reschedule_order(p_order_id text, p_scheduled_at timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  PERFORM pg_advisory_xact_lock(hashtext('carzone_customer:' || v_cust.id));
  PERFORM public._assert_customer_can_book(v_cust.id, v_order.vehicle_id, p_scheduled_at, v_order.duration_min, v_order.id);

  UPDATE public.orders SET scheduled_at = p_scheduled_at, updated_at = now() WHERE id = v_order.id;

  RETURN public._order_json(v_order.id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.close_stale_orders()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_id text;
  v_closed integer := 0;
BEGIN
  -- Never confirmed by the wash: release it 30 minutes after the slot started.
  FOR v_id IN
    SELECT id FROM public.orders
    WHERE status = 'pending' AND scheduled_at < now() - interval '30 minutes'
    FOR UPDATE SKIP LOCKED
  LOOP
    UPDATE public.orders
    SET status = 'cancelled', cancel_reason = 'expired_unconfirmed',
        cancelled_by_type = 'system', cancelled_by_id = 'auto_close',
        cancelled_at = now(), updated_at = now()
    WHERE id = v_id;
    INSERT INTO public.order_events (order_id, status, actor_type, actor_id)
    VALUES (v_id, 'cancelled', 'system', 'auto_close');
    v_closed := v_closed + 1;
  END LOOP;

  -- Confirmed but the car never arrived: no-show 60 minutes after the slot ended.
  FOR v_id IN
    SELECT id FROM public.orders
    WHERE status = 'confirmed'
      AND scheduled_at + make_interval(mins => duration_min) < now() - interval '60 minutes'
    FOR UPDATE SKIP LOCKED
  LOOP
    UPDATE public.orders SET status = 'no_show', updated_at = now() WHERE id = v_id;
    INSERT INTO public.order_events (order_id, status, actor_type, actor_id)
    VALUES (v_id, 'no_show', 'system', 'auto_close');
    v_closed := v_closed + 1;
  END LOOP;

  RETURN v_closed;
END;
$function$;

REVOKE ALL ON FUNCTION public.close_stale_orders() FROM PUBLIC, anon, authenticated;

SELECT cron.schedule('close-stale-orders', '*/10 * * * *', $$SELECT public.close_stale_orders()$$);
