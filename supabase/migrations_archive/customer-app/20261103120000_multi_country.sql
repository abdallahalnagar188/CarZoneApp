-- Branches outside Egypt: countries with their currency and time zone, a
-- country and a centre for every area, booking times in the branch's own
-- time zone, and one search that sorts washes by real distance.
-- Egypt keeps working as before: every existing area is Egyptian and
-- Africa/Cairo stays the fallback time zone.

-- 1. Countries -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.countries (
  code text PRIMARY KEY CHECK (code ~ '^[A-Z]{2}$'),
  name jsonb NOT NULL,
  currency text NOT NULL,
  currency_symbol jsonb NOT NULL,
  currency_decimals smallint NOT NULL DEFAULT 2 CHECK (currency_decimals BETWEEN 0 AND 3),
  timezone text NOT NULL,
  dial_code text NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read countries" ON public.countries;
CREATE POLICY "Anyone can read countries" ON public.countries FOR SELECT TO anon, authenticated USING (true);
GRANT SELECT ON public.countries TO anon, authenticated;

INSERT INTO public.countries (code, name, currency, currency_symbol, currency_decimals, timezone, dial_code, lat, lng, sort_order)
VALUES
  ('EG', jsonb_build_object('ar','مصر','en','Egypt'), 'EGP', jsonb_build_object('ar','ج.م','en','EGP'), 2, 'Africa/Cairo', '+20', 30.0444, 31.2357, 0),
  ('SA', jsonb_build_object('ar','السعودية','en','Saudi Arabia'), 'SAR', jsonb_build_object('ar','ر.س','en','SAR'), 2, 'Asia/Riyadh', '+966', 24.7136, 46.6753, 1),
  ('AE', jsonb_build_object('ar','الإمارات','en','United Arab Emirates'), 'AED', jsonb_build_object('ar','د.إ','en','AED'), 2, 'Asia/Dubai', '+971', 25.2048, 55.2708, 2),
  ('KW', jsonb_build_object('ar','الكويت','en','Kuwait'), 'KWD', jsonb_build_object('ar','د.ك','en','KWD'), 3, 'Asia/Kuwait', '+965', 29.3759, 47.9774, 3),
  ('QA', jsonb_build_object('ar','قطر','en','Qatar'), 'QAR', jsonb_build_object('ar','ر.ق','en','QAR'), 2, 'Asia/Qatar', '+974', 25.2854, 51.531, 4),
  ('BH', jsonb_build_object('ar','البحرين','en','Bahrain'), 'BHD', jsonb_build_object('ar','د.ب','en','BHD'), 3, 'Asia/Bahrain', '+973', 26.2285, 50.586, 5),
  ('OM', jsonb_build_object('ar','عُمان','en','Oman'), 'OMR', jsonb_build_object('ar','ر.ع','en','OMR'), 3, 'Asia/Muscat', '+968', 23.588, 58.3829, 6),
  ('JO', jsonb_build_object('ar','الأردن','en','Jordan'), 'JOD', jsonb_build_object('ar','د.أ','en','JOD'), 3, 'Asia/Amman', '+962', 31.9454, 35.9284, 7),
  ('LB', jsonb_build_object('ar','لبنان','en','Lebanon'), 'LBP', jsonb_build_object('ar','ل.ل','en','LBP'), 0, 'Asia/Beirut', '+961', 33.8938, 35.5018, 8),
  ('IQ', jsonb_build_object('ar','العراق','en','Iraq'), 'IQD', jsonb_build_object('ar','د.ع','en','IQD'), 0, 'Asia/Baghdad', '+964', 33.3152, 44.3661, 9),
  ('SY', jsonb_build_object('ar','سوريا','en','Syria'), 'SYP', jsonb_build_object('ar','ل.س','en','SYP'), 0, 'Asia/Damascus', '+963', 33.5138, 36.2765, 10),
  ('PS', jsonb_build_object('ar','فلسطين','en','Palestine'), 'ILS', jsonb_build_object('ar','₪','en','ILS'), 2, 'Asia/Hebron', '+970', 31.9038, 35.2034, 11),
  ('YE', jsonb_build_object('ar','اليمن','en','Yemen'), 'YER', jsonb_build_object('ar','ر.ي','en','YER'), 0, 'Asia/Aden', '+967', 15.3694, 44.191, 12),
  ('LY', jsonb_build_object('ar','ليبيا','en','Libya'), 'LYD', jsonb_build_object('ar','د.ل','en','LYD'), 3, 'Africa/Tripoli', '+218', 32.8872, 13.1913, 13),
  ('TN', jsonb_build_object('ar','تونس','en','Tunisia'), 'TND', jsonb_build_object('ar','د.ت','en','TND'), 3, 'Africa/Tunis', '+216', 36.8065, 10.1815, 14),
  ('DZ', jsonb_build_object('ar','الجزائر','en','Algeria'), 'DZD', jsonb_build_object('ar','د.ج','en','DZD'), 2, 'Africa/Algiers', '+213', 36.7538, 3.0588, 15),
  ('MA', jsonb_build_object('ar','المغرب','en','Morocco'), 'MAD', jsonb_build_object('ar','د.م','en','MAD'), 2, 'Africa/Casablanca', '+212', 33.5731, -7.5898, 16),
  ('SD', jsonb_build_object('ar','السودان','en','Sudan'), 'SDG', jsonb_build_object('ar','ج.س','en','SDG'), 2, 'Africa/Khartoum', '+249', 15.5007, 32.5599, 17),
  ('MR', jsonb_build_object('ar','موريتانيا','en','Mauritania'), 'MRU', jsonb_build_object('ar','أ.م','en','MRU'), 2, 'Africa/Nouakchott', '+222', 18.0735, -15.9582, 18),
  ('SO', jsonb_build_object('ar','الصومال','en','Somalia'), 'SOS', jsonb_build_object('ar','ش.ص','en','SOS'), 2, 'Africa/Mogadishu', '+252', 2.0469, 45.3182, 19),
  ('DJ', jsonb_build_object('ar','جيبوتي','en','Djibouti'), 'DJF', jsonb_build_object('ar','ف.ج','en','DJF'), 0, 'Africa/Djibouti', '+253', 11.5721, 43.1456, 20),
  ('KM', jsonb_build_object('ar','جزر القمر','en','Comoros'), 'KMF', jsonb_build_object('ar','ف.ق','en','KMF'), 0, 'Indian/Comoro', '+269', -11.7172, 43.2473, 21)
ON CONFLICT (code) DO UPDATE SET
  name = excluded.name, currency = excluded.currency, currency_symbol = excluded.currency_symbol,
  currency_decimals = excluded.currency_decimals, timezone = excluded.timezone,
  dial_code = excluded.dial_code, lat = excluded.lat, lng = excluded.lng,
  sort_order = excluded.sort_order, updated_at = now();

-- 2. Areas belong to a country and have a centre ---------------------------
ALTER TABLE public.areas ADD COLUMN IF NOT EXISTS country_code text NOT NULL DEFAULT 'EG' REFERENCES public.countries(code);
ALTER TABLE public.areas ADD COLUMN IF NOT EXISTS lat double precision;
ALTER TABLE public.areas ADD COLUMN IF NOT EXISTS lng double precision;
CREATE INDEX IF NOT EXISTS idx_areas_country ON public.areas(country_code);

UPDATE public.areas SET lat = 30.0566, lng = 31.3301 WHERE id = 'nasr' AND lat IS NULL;
UPDATE public.areas SET lat = 30.0911, lng = 31.3226 WHERE id = 'helio' AND lat IS NULL;
UPDATE public.areas SET lat = 30.025, lng = 31.46 WHERE id = 'nc' AND lat IS NULL;
UPDATE public.areas SET lat = 29.9602, lng = 31.2569 WHERE id = 'maadi' AND lat IS NULL;
UPDATE public.areas SET lat = 30.0609, lng = 31.2197 WHERE id = 'zamalek' AND lat IS NULL;
UPDATE public.areas SET lat = 30.0569, lng = 31.2001 WHERE id = 'moh' AND lat IS NULL;
UPDATE public.areas SET lat = 30.0381, lng = 30.985 WHERE id = 'zayed' AND lat IS NULL;
UPDATE public.areas SET lat = 29.9727, lng = 30.9437 WHERE id = 'oct' AND lat IS NULL;

-- An area without a centre takes the average of its branches.
UPDATE public.areas a SET lat = s.lat, lng = s.lng
FROM (SELECT area_id, avg(lat) lat, avg(lng) lng FROM public.branches GROUP BY area_id) s
WHERE s.area_id = a.id AND a.lat IS NULL;

-- 3. The branch's time zone, from its area's country -----------------------
CREATE OR REPLACE FUNCTION public.branch_timezone(p_branch_id text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT coalesce((
    SELECT c.timezone
    FROM public.branches b
    JOIN public.areas a ON a.id = b.area_id
    JOIN public.countries c ON c.code = a.country_code
    WHERE b.id = p_branch_id
  ), 'Africa/Cairo');
$function$;
GRANT EXECUTE ON FUNCTION public.branch_timezone(text) TO anon, authenticated;

-- 4. Booking times in the branch's time zone --------------------------------
CREATE OR REPLACE FUNCTION public.format_booking_time(p_at timestamp with time zone, p_lang text, p_tz text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_local timestamp := p_at AT TIME ZONE coalesce(p_tz, 'Africa/Cairo');
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
$function$;

CREATE OR REPLACE FUNCTION public.format_booking_time(p_at timestamp with time zone, p_lang text DEFAULT 'ar'::text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  -- Kept for callers without a branch: Cairo, as before.
  SELECT public.format_booking_time(p_at, p_lang, 'Africa/Cairo');
$function$;

CREATE OR REPLACE FUNCTION public._assert_slot_bookable(p_branch branches, p_start timestamp with time zone, p_duration integer, p_exclude_order text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_tz text := public.branch_timezone(p_branch.id);
  v_local timestamp := p_start AT TIME ZONE v_tz;
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
  IF v_local::date > (now() AT TIME ZONE v_tz)::date + p_branch.max_advance_days THEN
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
  v_today date;
  v_tz text := public.branch_timezone(p_branch_id);
BEGIN
  SELECT * INTO v_branch FROM public.branches WHERE id = p_branch_id;
  IF NOT FOUND OR NOT v_branch.active THEN
    RETURN;
  END IF;

  v_today := (now() AT TIME ZONE v_tz)::date;
  IF p_date < v_today OR p_date > v_today + v_branch.max_advance_days THEN
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
    v_slot_tz := v_slot_local AT TIME ZONE v_tz;
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

CREATE OR REPLACE FUNCTION public.close_stale_orders()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id text;
  v_order public.orders%rowtype;
  v_closed integer := 0;
  v_unconfirmed text := 'اتلغى تلقائيًا لأن المغسلة ما أكدتش في الوقت المحدد — Cancelled because the wash did not confirm before the appointment';
  v_not_started text := 'أُغلق الطلب لأن الخدمة لم تبدأ بعد تسجيل الوصول — Closed because the service never started after check-in';
begin
  for v_order in
    select o.* from public.orders o
    where o.status = 'pending'
      and o.created_at < now() - interval '10 minutes'
      and o.scheduled_at > now()
      and not exists (
        select 1 from public.vendor_notifications n
        where n.href = '/orders/' || o.id and n.title ->> 'ar' like 'تذكير:%'
      )
  loop
    perform public.notify_wash(v_order.business_id, v_order.branch_id, 'new_booking',
      'تذكير: حجز بانتظار تأكيدك ' || v_order.number,
      coalesce((select name ->> 'ar' from public.branches where id = v_order.branch_id), '')
        || ' · ' || public.format_booking_time(v_order.scheduled_at, 'ar', public.branch_timezone(v_order.branch_id))
        || ' · يُلغى تلقائيًا لو لم يُؤكَّد قبل الموعد',
      '/orders/' || v_order.id);
  end loop;

  for v_id in
    select id from public.orders
    where status = 'pending' and scheduled_at <= now()
    for update skip locked
  loop
    update public.orders
    set status = 'cancelled', cancel_reason = v_unconfirmed,
        cancelled_by_type = 'system', cancelled_by_id = 'auto_close',
        cancelled_at = now(), updated_at = now()
    where id = v_id;
    insert into public.order_events (order_id, status, actor_type, actor_id)
    values (v_id, 'cancelled', 'system', 'auto_close');
    v_closed := v_closed + 1;
  end loop;

  for v_id in
    select id from public.orders
    where status = 'confirmed'
      and scheduled_at + make_interval(mins => duration_min) < now() - interval '60 minutes'
    for update skip locked
  loop
    update public.orders set status = 'no_show', updated_at = now() where id = v_id;
    insert into public.order_events (order_id, status, actor_type, actor_id)
    values (v_id, 'no_show', 'system', 'auto_close');
    v_closed := v_closed + 1;
  end loop;

  for v_id in
    select id from public.orders
    where status = 'waiting'
      and scheduled_at + make_interval(mins => duration_min) < now() - interval '12 hours'
    for update skip locked
  loop
    update public.orders
    set status = 'cancelled', cancel_reason = v_not_started,
        cancelled_by_type = 'system', cancelled_by_id = 'auto_close',
        cancelled_at = now(), updated_at = now()
    where id = v_id;
    insert into public.order_events (order_id, status, actor_type, actor_id)
    values (v_id, 'cancelled', 'system', 'auto_close');
    v_closed := v_closed + 1;
  end loop;

  return v_closed;
end;
$function$;

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
  if tg_op = 'INSERT' and new.status not in ('pending', 'confirmed') then
    return new;
  end if;

  v_when_ar := public.format_booking_time(new.scheduled_at, 'ar', public.branch_timezone(new.branch_id));
  v_when_en := public.format_booking_time(new.scheduled_at, 'en', public.branch_timezone(new.branch_id));
  v_reason := nullif(trim(coalesce(new.cancel_reason, '')), '');

  if new.status = 'pending' then
    if tg_op = 'INSERT' then
      v_type := 'created';
      v_title := jsonb_build_object('ar', 'تم إرسال طلب الحجز', 'en', 'Booking request sent');
      v_body := jsonb_build_object('ar', 'طلبك رقم #' || new.number || ' وصل للمغسلة وبانتظار تأكيدها', 'en', 'Order #' || new.number || ' is waiting for the wash to confirm');
    else
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
    v_type := 'cancelled';
    v_title := jsonb_build_object('ar', 'تم إغلاق الحجز لعدم الحضور', 'en', 'Booking closed: no show');
    v_body := jsonb_build_object('ar', 'تم إغلاق حجزك رقم #' || new.number || ' لأنك لم تحضر في الموعد', 'en', 'Booking #' || new.number || ' was closed because you did not arrive');
  elsif new.status = 'cancelled' then
    v_type := 'cancelled';
    v_title := jsonb_build_object('ar', 'تم إلغاء الحجز', 'en', 'Booking cancelled');
    v_body := case
      when new.cancelled_by_type = 'customer' then
        jsonb_build_object('ar', 'تم إلغاء حجزك رقم #' || new.number || ' بناءً على طلبك', 'en', 'Booking #' || new.number || ' was cancelled at your request')
      when new.cancelled_by_type = 'system' and v_reason in (
        'expired_unconfirmed',
        'اتلغى تلقائيًا لأن المغسلة ما أكدتش في الوقت المحدد — Cancelled because the wash did not confirm before the appointment'
      ) then
        jsonb_build_object('ar', 'تم إلغاء طلبك رقم #' || new.number || ' لأن المغسلة لم تؤكده قبل الموعد', 'en', 'Order #' || new.number || ' was cancelled because the wash did not confirm it in time')
      when new.cancelled_by_type = 'system' and v_reason in (
        'expired_not_started',
        'أُغلق الطلب لأن الخدمة لم تبدأ بعد تسجيل الوصول — Closed because the service never started after check-in'
      ) then
        jsonb_build_object('ar', 'تم إغلاق طلبك رقم #' || new.number || ' لأن الخدمة لم تبدأ — تواصل مع المغسلة لو محتاج مساعدة', 'en', 'Order #' || new.number || ' was closed because the service never started. Contact the wash if you need help')
      when new.cancelled_by_type = 'admin' then
        jsonb_build_object('ar', 'ألغت إدارة Wash Up حجزك رقم #' || new.number || coalesce(': ' || v_reason, ''), 'en', 'Wash Up cancelled booking #' || new.number || coalesce(': ' || v_reason, ''))
      else
        jsonb_build_object('ar', 'ألغت المغسلة حجزك رقم #' || new.number || coalesce(': ' || v_reason, ''), 'en', 'The wash cancelled booking #' || new.number || coalesce(': ' || v_reason, ''))
    end;
  else
    return new;
  end if;

  insert into public.customer_notifications (id, customer_id, type, title, body, href, order_id, read, created_at)
  values ('cn_' || new.id || '_' || new.status || '_' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSUS'),
          new.customer_id, v_type, v_title, v_body, '/booking_details?id=' || new.id, new.id, false, clock_timestamp())
  on conflict (id) do nothing;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.wash_order_notifications()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_branch text;
  v_when text;
  v_customer_reason text;
begin
  select name ->> 'ar' into v_branch from public.branches where id = new.branch_id;
  v_when := public.format_booking_time(new.scheduled_at, 'ar', public.branch_timezone(new.branch_id));
  if tg_op = 'INSERT' then
    if new.source = 'app' then
      perform public.notify_wash(new.business_id, new.branch_id, 'new_booking',
        'حجز جديد من التطبيق ' || new.number,
        coalesce(v_branch, '') || ' · ' || v_when || case when new.status = 'pending' then ' · بانتظار تأكيدك' else ' · تم تأكيده تلقائيًا' end,
        '/orders/' || new.id);
    end if;
  elsif new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    if new.cancelled_by_type = 'customer' then
      v_customer_reason := nullif(nullif(new.cancel_reason, 'Cancelled by customer'), 'ألغاه العميل — Cancelled by the customer');
      perform public.notify_wash(new.business_id, new.branch_id, 'booking_cancelled',
        'العميل ألغى الحجز ' || new.number,
        coalesce(v_branch, '') || ' · ' || v_when || coalesce(' · ' || v_customer_reason, ''),
        '/orders/' || new.id);
    elsif new.cancelled_by_type = 'system' and new.cancel_reason in (
      'expired_unconfirmed',
      'اتلغى تلقائيًا لأن المغسلة ما أكدتش في الوقت المحدد — Cancelled because the wash did not confirm before the appointment'
    ) then
      perform public.notify_wash(new.business_id, new.branch_id, 'booking_cancelled',
        'انتهى وقت تأكيد الحجز ' || new.number,
        coalesce(v_branch, '') || ' · ' || v_when || ' · ألغي تلقائيًا لأنه لم يؤكَّد قبل الموعد',
        '/orders/' || new.id);
    elsif new.cancelled_by_type = 'system' and new.cancel_reason in (
      'expired_not_started',
      'أُغلق الطلب لأن الخدمة لم تبدأ بعد تسجيل الوصول — Closed because the service never started after check-in'
    ) then
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

-- 5. Washes around a point, nearest first -----------------------------------
-- Runs as the caller, so branch and service visibility stay the same as a
-- plain select. p_country limits the list to one country; p_max_km to a radius.
CREATE OR REPLACE FUNCTION public.discover_branches(
  p_lat double precision,
  p_lng double precision,
  p_country text DEFAULT NULL,
  p_category text DEFAULT NULL,
  p_max_km double precision DEFAULT NULL,
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0
)
 RETURNS TABLE(branch jsonb, km double precision, from_price numeric, country_code text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  WITH b AS (
    SELECT br.*, a.country_code AS area_country,
      6371 * 2 * asin(sqrt(
        power(sin(radians(br.lat - p_lat) / 2), 2)
        + cos(radians(p_lat)) * cos(radians(br.lat)) * power(sin(radians(br.lng - p_lng) / 2), 2)
      )) AS dist
    FROM public.branches br
    JOIN public.areas a ON a.id = br.area_id
    WHERE br.active
      AND (p_country IS NULL OR a.country_code = p_country)
  ),
  priced AS (
    SELECT b.*, (
      SELECT min(s.price) FROM public.services s
      WHERE s.branch_id = b.id AND s.active AND s.type = 'primary'
        AND (p_category IS NULL OR s.category_id = p_category)
    ) AS price
    FROM b
  )
  SELECT to_jsonb(p) - 'area_country' - 'dist' - 'price', p.dist, p.price, p.area_country
  FROM priced p
  WHERE (p_max_km IS NULL OR p.dist <= p_max_km)
    AND (p_category IS NULL OR p.price IS NOT NULL)
  ORDER BY p.dist
  LIMIT greatest(least(p_limit, 50), 1) OFFSET greatest(p_offset, 0);
$function$;
GRANT EXECUTE ON FUNCTION public.discover_branches(double precision, double precision, text, text, double precision, integer, integer) TO anon, authenticated;
