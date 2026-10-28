-- Migration: 20261028140000_booking_timing_and_friendly_dates.sql
-- Booking timing and notification wording, found while testing the system end to end:
--
-- 1. A booking the wash never confirmed was cancelled 30 minutes AFTER its slot started,
--    so the customer could already be at the wash. Now it is cancelled at the slot start,
--    and the wash gets one reminder 10 minutes after the booking arrives.
-- 2. Washes that confirm by hand got bookings 20 minutes ahead, too little time to confirm.
--    Their slots now start at least 30 minutes ahead (or the branch's own lead time if longer).
-- 3. A checked-in car the wash never started stayed "waiting" for days. 12 hours after the
--    slot ended it is cancelled (expired_not_started) and both sides are told.
-- 4. Notifications showed the time as "2026-10-28 15:00"; they now say
--    "الأربعاء 28 أكتوبر · 3:00 م" / "Wed 28 Oct · 3:00 PM" (Cairo time).
-- 5. get_support_info(): the app's help screen reads the support phone, email and hours from
--    platform settings (the table itself stays closed to app users).

-- ---------------------------------------------------------------------------
-- Friendly booking time, Cairo time, Western digits.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.format_booking_time(p_at timestamptz, p_lang text DEFAULT 'ar')
RETURNS text
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $func$
DECLARE
  v_local timestamp := p_at AT TIME ZONE 'Africa/Cairo';
  v_hour int := extract(hour FROM v_local)::int;
  v_clock text := ((v_hour + 11) % 12 + 1)::text || ':' || to_char(v_local, 'MI');
BEGIN
  IF p_at IS NULL THEN
    RETURN NULL;
  END IF;
  IF p_lang = 'en' THEN
    RETURN to_char(v_local, 'Dy FMDD Mon') || ' · ' || v_clock || CASE WHEN v_hour < 12 THEN ' AM' ELSE ' PM' END;
  END IF;
  RETURN (ARRAY['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'])[extract(dow FROM v_local)::int + 1]
    || ' ' || extract(day FROM v_local)::int || ' '
    || (ARRAY['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'])[extract(month FROM v_local)::int]
    || ' · ' || v_clock || CASE WHEN v_hour < 12 THEN ' ص' ELSE ' م' END;
END;
$func$;

-- ---------------------------------------------------------------------------
-- Washes that confirm by hand need time to do it.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.booking_lead_min(p_branch public.branches)
RETURNS int
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $func$
  SELECT CASE WHEN p_branch.auto_confirm THEN p_branch.lead_time_min::int
              ELSE greatest(p_branch.lead_time_min::int, 30) END;
$func$;

CREATE OR REPLACE FUNCTION public._assert_slot_bookable(p_branch branches, p_start timestamp with time zone, p_duration integer, p_exclude_order text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_local timestamp := p_start AT TIME ZONE 'Africa/Cairo';
  v_end timestamptz := p_start + make_interval(mins => p_duration);
  v_hours public.branch_working_hours%ROWTYPE;
  v_open int;
  v_close int;
  v_start_min int;
  v_used int;
BEGIN
  IF p_start < now() + make_interval(mins => public.booking_lead_min(p_branch)) THEN
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
$function$;

CREATE OR REPLACE FUNCTION public.get_branch_slots(p_branch_id text, p_date date, p_duration integer DEFAULT 30, p_exclude_order text DEFAULT NULL::text, p_include_full boolean DEFAULT false)
 RETURNS TABLE(start_at timestamp with time zone, local_time text, free_capacity integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
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
  v_earliest := now() + make_interval(mins => public.booking_lead_min(v_branch));

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

-- ---------------------------------------------------------------------------
-- Auto close: remind, cancel at the slot start, close stale check-ins.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_stale_orders()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_id text;
  v_order public.orders%ROWTYPE;
  v_closed integer := 0;
BEGIN
  -- Still unconfirmed 10 minutes after it arrived: remind the wash once.
  FOR v_order IN
    SELECT o.* FROM public.orders o
    WHERE o.status = 'pending'
      AND o.created_at < now() - interval '10 minutes'
      AND o.scheduled_at > now()
      AND NOT EXISTS (
        SELECT 1 FROM public.vendor_notifications n
        WHERE n.href = '/orders/' || o.id AND n.title ->> 'ar' LIKE 'تذكير:%'
      )
  LOOP
    PERFORM public.notify_wash(v_order.business_id, v_order.branch_id, 'new_booking',
      'تذكير: حجز بانتظار تأكيدك ' || v_order.number,
      coalesce((SELECT name ->> 'ar' FROM public.branches WHERE id = v_order.branch_id), '')
        || ' · ' || public.format_booking_time(v_order.scheduled_at)
        || ' · يُلغى تلقائيًا لو لم يُؤكَّد قبل الموعد',
      '/orders/' || v_order.id);
  END LOOP;

  -- Never confirmed by the wash: release it when the slot starts.
  FOR v_id IN
    SELECT id FROM public.orders
    WHERE status = 'pending' AND scheduled_at <= now()
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

  -- Checked in but the wash never started it: close it 12 hours after the slot ended.
  -- (in_service is left to the wash: the car is being worked on.)
  FOR v_id IN
    SELECT id FROM public.orders
    WHERE status = 'waiting'
      AND scheduled_at + make_interval(mins => duration_min) < now() - interval '12 hours'
    FOR UPDATE SKIP LOCKED
  LOOP
    UPDATE public.orders
    SET status = 'cancelled', cancel_reason = 'expired_not_started',
        cancelled_by_type = 'system', cancelled_by_id = 'auto_close',
        cancelled_at = now(), updated_at = now()
    WHERE id = v_id;
    INSERT INTO public.order_events (order_id, status, actor_type, actor_id)
    VALUES (v_id, 'cancelled', 'system', 'auto_close');
    v_closed := v_closed + 1;
  END LOOP;

  RETURN v_closed;
END;
$function$;

-- ---------------------------------------------------------------------------
-- Customer notifications: friendly time, wording for the new system cancel.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_order_status_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_type text;
  v_title jsonb;
  v_body jsonb;
  v_when_ar text;
  v_when_en text;
  v_reason text;
begin
  if new.customer_id is null then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;
  -- A walk-in is standing at the wash: no "booking" notification for it.
  if tg_op = 'INSERT' and new.status not in ('pending', 'confirmed') then
    return new;
  end if;

  v_when_ar := public.format_booking_time(new.scheduled_at, 'ar');
  v_when_en := public.format_booking_time(new.scheduled_at, 'en');
  v_reason := nullif(trim(coalesce(new.cancel_reason, '')), '');

  if new.status = 'pending' then
    if tg_op = 'INSERT' then
      v_type := 'created';
      v_title := jsonb_build_object('ar', 'تم إرسال طلب الحجز', 'en', 'Booking request sent');
      v_body := jsonb_build_object('ar', 'طلبك رقم #' || new.number || ' وصل للمغسلة وبانتظار تأكيدها', 'en', 'Order #' || new.number || ' is waiting for the wash to confirm');
    else
      -- Types are limited to what the app knows (customer_notifications_type_check): a moved
      -- booking waiting for confirmation is a "created" one again.
      v_type := 'created';
      v_title := jsonb_build_object('ar', 'تم تغيير موعد الحجز', 'en', 'Booking rescheduled');
      v_body := jsonb_build_object('ar', 'الموعد الجديد لطلبك رقم #' || new.number || ' (' || v_when_ar || ') بانتظار تأكيد المغسلة', 'en', 'The new time for order #' || new.number || ' (' || v_when_en || ') is waiting for the wash to confirm');
    end if;
  elsif new.status = 'confirmed' then
    v_type := 'confirmed';
    v_title := jsonb_build_object('ar', 'تم تأكيد الحجز', 'en', 'Booking confirmed');
    v_body := jsonb_build_object('ar', 'تم تأكيد حجزك رقم #' || new.number || ' — ' || v_when_ar, 'en', 'Your booking #' || new.number || ' is confirmed for ' || v_when_en);
  elsif new.status = 'waiting' then
    v_type := 'waiting';
    v_title := jsonb_build_object('ar', 'تم تسجيل وصولك', 'en', 'Checked in');
    v_body := jsonb_build_object('ar', 'وصلت سيارتك للمغسلة وهي في الدور للطلب رقم #' || new.number, 'en', 'Your car is checked in and in the queue for order #' || new.number);
  elsif new.status = 'in_service' then
    v_type := 'in_service';
    v_title := jsonb_build_object('ar', 'بدأ غسيل سيارتك', 'en', 'Washing in progress');
    v_body := jsonb_build_object('ar', 'بدأ العمل على سيارتك للطلب رقم #' || new.number, 'en', 'Work on your car has started for order #' || new.number);
  elsif new.status = 'completed' then
    v_type := 'completed';
    v_title := jsonb_build_object('ar', 'سيارتك جاهزة', 'en', 'Your car is ready');
    v_body := jsonb_build_object('ar', 'خلصت الخدمة وسيارتك جاهزة للاستلام — الطلب رقم #' || new.number, 'en', 'Service done, your car is ready for pickup — order #' || new.number);
  elsif new.status = 'no_show' then
    v_type := 'cancelled'; -- the app has no "no_show" type; the booking is closed either way
    v_title := jsonb_build_object('ar', 'تم إغلاق الحجز لعدم الحضور', 'en', 'Booking closed: no show');
    v_body := jsonb_build_object('ar', 'تم إغلاق حجزك رقم #' || new.number || ' لأنك لم تحضر في الموعد', 'en', 'Booking #' || new.number || ' was closed because you did not arrive');
  elsif new.status = 'cancelled' then
    v_type := 'cancelled';
    v_title := jsonb_build_object('ar', 'تم إلغاء الحجز', 'en', 'Booking cancelled');
    v_body := case
      when new.cancelled_by_type = 'customer' then
        jsonb_build_object('ar', 'تم إلغاء حجزك رقم #' || new.number || ' بناءً على طلبك', 'en', 'Booking #' || new.number || ' was cancelled at your request')
      when new.cancelled_by_type = 'system' and v_reason = 'expired_unconfirmed' then
        jsonb_build_object('ar', 'تم إلغاء طلبك رقم #' || new.number || ' لأن المغسلة لم تؤكده قبل الموعد', 'en', 'Order #' || new.number || ' was cancelled because the wash did not confirm it in time')
      when new.cancelled_by_type = 'system' and v_reason = 'expired_not_started' then
        jsonb_build_object('ar', 'تم إغلاق طلبك رقم #' || new.number || ' لأن الخدمة لم تبدأ — تواصل مع المغسلة لو محتاج مساعدة', 'en', 'Order #' || new.number || ' was closed because the service never started. Contact the wash if you need help')
      when new.cancelled_by_type = 'admin' then
        jsonb_build_object('ar', 'ألغت إدارة WashUp حجزك رقم #' || new.number || coalesce(': ' || v_reason, ''), 'en', 'WashUp cancelled booking #' || new.number || coalesce(': ' || v_reason, ''))
      else
        jsonb_build_object('ar', 'ألغت المغسلة حجزك رقم #' || new.number || coalesce(': ' || v_reason, ''), 'en', 'The wash cancelled booking #' || new.number || coalesce(': ' || v_reason, ''))
    end;
  else
    return new;
  end if;

  -- Timestamped id: a status can come back (reschedule → pending → confirmed again).
  insert into public.customer_notifications (id, customer_id, type, title, body, href, order_id, read, created_at)
  values ('cn_' || new.id || '_' || new.status || '_' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSUS'),
          new.customer_id, v_type, v_title, v_body, '/booking_details?id=' || new.id, new.id, false, clock_timestamp())
  on conflict (id) do nothing;

  return new;
end;
$function$;

-- ---------------------------------------------------------------------------
-- Wash notifications: same friendly time, and the new system cancel.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wash_order_notifications()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_branch text;
  v_when text;
begin
  select name ->> 'ar' into v_branch from public.branches where id = new.branch_id;
  v_when := public.format_booking_time(new.scheduled_at, 'ar');
  if tg_op = 'INSERT' then
    if new.source = 'app' then
      perform public.notify_wash(new.business_id, new.branch_id, 'new_booking',
        'حجز جديد من التطبيق ' || new.number,
        coalesce(v_branch, '') || ' · ' || v_when || case when new.status = 'pending' then ' · بانتظار تأكيدك' else ' · تم تأكيده تلقائيًا' end,
        '/orders/' || new.id);
    end if;
  elsif new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    if new.cancelled_by_type = 'customer' then
      perform public.notify_wash(new.business_id, new.branch_id, 'booking_cancelled',
        'العميل ألغى الحجز ' || new.number,
        coalesce(v_branch, '') || ' · ' || v_when || coalesce(' · ' || nullif(new.cancel_reason, 'Cancelled by customer'), ''),
        '/orders/' || new.id);
    elsif new.cancelled_by_type = 'system' and new.cancel_reason = 'expired_unconfirmed' then
      perform public.notify_wash(new.business_id, new.branch_id, 'booking_cancelled',
        'انتهى وقت تأكيد الحجز ' || new.number,
        coalesce(v_branch, '') || ' · ' || v_when || ' · ألغي تلقائيًا لأنه لم يؤكَّد قبل الموعد',
        '/orders/' || new.id);
    elsif new.cancelled_by_type = 'system' and new.cancel_reason = 'expired_not_started' then
      perform public.notify_wash(new.business_id, new.branch_id, 'booking_cancelled',
        'أُغلق طلب لم يبدأ ' || new.number,
        coalesce(v_branch, '') || ' · ' || v_when || ' · السيارة سُجّل وصولها ولم تبدأ الخدمة خلال 12 ساعة',
        '/orders/' || new.id);
    end if;
  elsif new.source = 'app' and new.scheduled_at is distinct from old.scheduled_at and new.status in ('pending', 'confirmed') then
    perform public.notify_wash(new.business_id, new.branch_id, 'new_booking',
      'العميل غيّر موعد الحجز ' || new.number,
      coalesce(v_branch, '') || ' · الموعد الجديد ' || v_when || case when new.status = 'pending' then ' · بانتظار تأكيدك' else '' end,
      '/orders/' || new.id);
  end if;
  return new;
end $function$;

-- ---------------------------------------------------------------------------
-- Support details for the app's help screen (the settings table stays closed).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_support_info()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $func$
  SELECT jsonb_build_object(
    'phone', nullif(trim(value ->> 'supportPhone'), ''),
    'email', nullif(trim(value ->> 'supportEmail'), ''),
    'hours', value -> 'supportHours'
  )
  FROM public.platform_settings
  WHERE key = 'general';
$func$;

REVOKE EXECUTE ON FUNCTION public.get_support_info() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_support_info() TO anon, authenticated;
