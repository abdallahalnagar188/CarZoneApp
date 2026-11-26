-- get_branch_slots: optionally return fully booked slots (free_capacity = 0)
-- so the customer app can show them as disabled instead of hiding them.
DROP FUNCTION IF EXISTS public.get_branch_slots(text, date, integer, text);

CREATE OR REPLACE FUNCTION public.get_branch_slots(
  p_branch_id text,
  p_date date,
  p_duration integer DEFAULT 30,
  p_exclude_order text DEFAULT NULL,
  p_include_full boolean DEFAULT false
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
    IF v_free > 0 OR p_include_full THEN
      start_at := v_slot_tz;
      local_time := to_char(v_slot_local, 'HH24:MI');
      free_capacity := greatest(v_free, 0);
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_branch_slots(text, date, integer, text, boolean) TO authenticated, anon;
