-- Migration: 20261019180000_customer_notifications_and_slots.sql
-- 1. Fix order number sequences to avoid duplicate key collisions with existing orders
ALTER SEQUENCE IF EXISTS public.order_number_app_seq MAXVALUE 999999999;
SELECT setval('public.order_number_app_seq', greatest(50000, nextval('public.order_number_app_seq')), true);

ALTER SEQUENCE IF EXISTS public.order_number_walk_in_seq MAXVALUE 999999999;
SELECT setval('public.order_number_walk_in_seq', greatest(60000, nextval('public.order_number_walk_in_seq')), true);

ALTER SEQUENCE IF EXISTS public.order_number_phone_seq MAXVALUE 999999999;
SELECT setval('public.order_number_phone_seq', greatest(70000, nextval('public.order_number_phone_seq')), true);

-- 2. Grant INSERT privilege and add RLS policy for customer_notifications
GRANT INSERT ON public.customer_notifications TO authenticated;

DROP POLICY IF EXISTS "Customers can insert own notifications" ON public.customer_notifications;
CREATE POLICY "Customers can insert own notifications"
ON public.customer_notifications
FOR INSERT
TO authenticated
WITH CHECK (
  customer_id = (SELECT current_customer_id())
  OR customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
);

-- 3. Expand customer_notifications_type_check to support order lifecycle status notifications
ALTER TABLE public.customer_notifications DROP CONSTRAINT IF EXISTS customer_notifications_type_check;

ALTER TABLE public.customer_notifications ADD CONSTRAINT customer_notifications_type_check 
CHECK (type = ANY (ARRAY[
  'created'::text,
  'confirmed'::text,
  'waiting'::text,
  'in_service'::text,
  'completed'::text,
  'cancelled'::text,
  'booking_confirmed'::text,
  'booking_cancelled'::text,
  'booking_reminder'::text,
  'order_ready'::text,
  'review_reminder'::text,
  'offer'::text,
  'complaint_update'::text,
  'system'::text,
  'reminder'::text
]));

-- 4. get_branch_slots RPC for canonical Cairo timezone availability
CREATE OR REPLACE FUNCTION public.get_branch_slots(
  p_branch_id text,
  p_date date,
  p_duration integer DEFAULT 30,
  p_exclude_order text DEFAULT NULL
)
RETURNS TABLE (
  start_at timestamptz,
  local_time text,
  free_capacity integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_branch branches%ROWTYPE;
  v_hours branch_working_hours%ROWTYPE;
  v_open int;
  v_close int;
  v_step int;
  v_dow int;
  v_min int;
  v_slot_local timestamp;
  v_slot_tz timestamptz;
  v_slot_end timestamptz;
  v_used int;
  v_free int;
  v_earliest timestamptz;
  v_cairo_today date;
BEGIN
  SELECT * INTO v_branch FROM public.branches WHERE id = p_branch_id;
  IF NOT FOUND OR NOT v_branch.active THEN
    RETURN;
  END IF;

  v_cairo_today := (now() AT TIME ZONE 'Africa/Cairo')::date;
  IF p_date < v_cairo_today OR p_date > v_cairo_today + v_branch.max_advance_days THEN
    RETURN;
  END IF;

  v_dow := extract(dow FROM p_date)::int;
  SELECT * INTO v_hours FROM public.branch_working_hours WHERE branch_id = p_branch_id AND weekday = v_dow;
  IF NOT FOUND OR v_hours.closed THEN
    RETURN;
  END IF;

  v_open := extract(hour FROM v_hours.opens_at)::int * 60 + extract(minute FROM v_hours.opens_at)::int;
  v_close := extract(hour FROM v_hours.closes_at)::int * 60 + extract(minute FROM v_hours.closes_at)::int;
  IF v_close <= v_open THEN
    v_close := v_close + 1440;
  END IF;

  v_step := greatest(v_branch.slot_interval_min, 15);
  v_earliest := now() + make_interval(mins => v_branch.lead_time_min);

  FOR v_min IN v_open..(v_close - p_duration) BY v_step LOOP
    v_slot_local := p_date + make_interval(hours => v_min / 60, mins => v_min % 60);
    v_slot_tz := v_slot_local AT TIME ZONE 'Africa/Cairo';
    v_slot_end := v_slot_tz + make_interval(mins => p_duration);

    -- Skip past or too soon slots
    IF v_slot_tz < v_earliest THEN
      CONTINUE;
    END IF;

    -- Check if blocked
    IF EXISTS (
      SELECT 1 FROM public.branch_blocked_slots b
      WHERE b.branch_id = p_branch_id AND b.starts_at < v_slot_end AND b.ends_at > v_slot_tz
    ) THEN
      CONTINUE;
    END IF;

    -- Count existing reservations
    SELECT count(*) INTO v_used
    FROM public.orders o
    WHERE o.branch_id = p_branch_id
      AND o.status IN ('pending', 'confirmed', 'waiting', 'in_service')
      AND o.id IS DISTINCT FROM p_exclude_order
      AND o.scheduled_at < v_slot_end
      AND o.scheduled_at + make_interval(mins => o.duration_min) > v_slot_tz;

    v_free := v_branch.capacity - v_used;
    IF v_free > 0 THEN
      start_at := v_slot_tz;
      local_time := to_char(v_slot_local, 'HH24:MI');
      free_capacity := v_free;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_branch_slots(text, date, integer, text) TO authenticated, anon;
