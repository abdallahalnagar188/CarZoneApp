-- WASH UP — production schema baseline (GAP-007).
--
-- Generated 2026-11-26 from project tbcmgdwzarfdgzzmmele (Postgres 17.11) with supabase/scripts/baseline-gen.sql
-- (a catalog query run in the SQL editor; no pg_dump access). It is the schema as it is live, after every
-- migration up to 20261127110000. The files it replaces are kept, unchanged, in supabase/migrations_archive/.
--
-- Verified 2026-11-26: replayed into a scratch schema in one rolled-back transaction on the live database and
-- compared object by object (columns, defaults, constraints, indexes, functions, grants, triggers, policies,
-- enums, views, comments, sequences): 1152 = 1152, none missing, none extra; the only difference is redundant
-- parentheses in staff_shift_patterns_days_check as Postgres prints it after a round trip (same expression).
-- Line endings are LF: 166 CR characters inside some live function bodies were dropped (the verified replay had
-- none either); the code is otherwise byte-for-byte what pg_get_functiondef returns.
-- Sections outside that replay (role, extensions, schema grant, realtime, cron, buckets) are short statements
-- generated from the same catalogs; read them before running this on a new project.
--
-- Covers the public schema, the project role washup_vendor_panel, extensions, the supabase_realtime tables,
-- pg_cron jobs and the storage bucket definitions. NOT included — set up by hand on a new project:
--   * Vault secrets (names only): firebase_service_account, panel_push_admin_url, panel_push_secret, panel_push_vendor_url, send_push_url, send_push_webhook_secret
--   * Auth settings (providers, SMS, redirect URLs), edge functions and their secrets (supabase/functions/*)
--   * Storage objects, and every table row (countries, areas, catalogs, settings: see supabase/seed-parts/)
--   * Supabase-managed defaults (default privileges, auth / storage / realtime schemas)
--
-- Usage: a new environment runs this file first (supabase db push / db reset). Production already has it:
-- its version is recorded in supabase_migrations.schema_migrations. Every later change is a new migration in
-- this folder, applied to production through the same history (never ad-hoc DDL in the dashboard).

set statement_timeout = 0;
set lock_timeout = 0;
set check_function_bodies = false;
set client_min_messages = warning;
select pg_catalog.set_config('search_path', '', false);

-- ==== Roles of this project (1) ====

do $r$ begin if not exists (select 1 from pg_roles where rolname = 'washup_vendor_panel') then create role washup_vendor_panel nologin nobypassrls noinherit; end if; end $r$;

-- ==== Role memberships (2) ====

grant washup_vendor_panel to postgres;

grant washup_vendor_panel to postgres;

-- ==== Extensions (6) ====

create extension if not exists pg_cron with schema pg_catalog;

create extension if not exists pg_net with schema extensions;

create extension if not exists pg_stat_statements with schema extensions;

create extension if not exists pgcrypto with schema extensions;

create extension if not exists supabase_vault with schema vault;

create extension if not exists "uuid-ossp" with schema extensions;

-- ==== Enum types (25) ====

create type public.account_status as enum ('active', 'suspended');

create type public.actor_type as enum ('customer', 'staff', 'admin', 'system');

create type public.admin_notification_type as enum ('application', 'complaint', 'critical_review', 'payment_issue', 'unusual_activity', 'system', 'finance_flag');

create type public.admin_role as enum ('super', 'operations', 'finance', 'support');

create type public.admin_status as enum ('active', 'inactive');

create type public.application_status as enum ('pending', 'needs_changes', 'approved', 'rejected');

create type public.business_status as enum ('pending', 'approved', 'active', 'suspended', 'rejected');

create type public.complaint_category as enum ('quality', 'pricing', 'behavior', 'booking', 'refund', 'other');

create type public.complaint_status as enum ('open', 'in_review', 'waiting', 'resolved', 'closed');

create type public.discount_type as enum ('percent', 'fixed');

create type public.offer_scope as enum ('platform', 'wash');

create type public.offer_status as enum ('draft', 'scheduled', 'active', 'expired', 'disabled');

create type public.order_payment_status as enum ('pending', 'paid', 'refunded');

create type public.order_source as enum ('app', 'walk_in', 'phone');

create type public.order_status as enum ('pending', 'confirmed', 'waiting', 'in_service', 'completed', 'cancelled', 'no_show');

create type public.payment_method as enum ('cash', 'card', 'online');

create type public.payment_status as enum ('paid', 'refunded');

create type public.payout_status as enum ('due', 'paid');

create type public.permission_level as enum ('none', 'view', 'manage');

create type public.review_status as enum ('visible', 'hidden');

create type public.service_type as enum ('primary', 'addon');

create type public.shift_review_status as enum ('open', 'submitted', 'reviewed', 'flagged');

create type public.staff_role as enum ('owner', 'manager', 'employee');

create type public.transaction_status as enum ('pending', 'paid', 'refunded', 'settled');

create type public.vendor_notification_type as enum ('new_booking', 'booking_cancelled', 'cash_difference', 'high_cancellation', 'branch_issue', 'daily_summary', 'review', 'platform', 'payout', 'shift');

-- ==== Functions (signatures without table types) (58) ====

CREATE OR REPLACE FUNCTION public._assert_customer_can_book(p_customer_id text, p_vehicle_id text, p_start timestamp with time zone, p_duration integer, p_exclude_order text DEFAULT NULL::text)
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
$function$
;

CREATE OR REPLACE FUNCTION public._order_json(p_order_id text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT to_jsonb(o)
    || jsonb_build_object(
         'order_items', coalesce((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.position) FROM public.order_items i WHERE i.order_id = o.id), '[]'::jsonb),
         'order_events', coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY e.at) FROM public.order_events e WHERE e.order_id = o.id), '[]'::jsonb)
       )
  FROM public.orders o
  WHERE o.id = p_order_id;
$function$
;

CREATE OR REPLACE FUNCTION public.add_customer_order_note(p_order_id text, p_note text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_customer text := public.current_active_customer_id(); v_order public.orders%rowtype; v_text text := btrim(coalesce(p_note, ''));
begin
  if v_customer is null then raise exception 'account_suspended'; end if;
  if char_length(v_text) = 0 or char_length(v_text) > 200 then raise exception 'invalid_note'; end if;
  select * into v_order from public.orders where id = p_order_id and customer_id = v_customer;
  if not found then raise exception 'order_not_found'; end if;
  if v_order.status not in ('pending', 'confirmed') then raise exception 'order_not_editable'; end if;
  if (select count(*) from public.order_notes n where n.order_id = v_order.id and n.author_staff_id is null and n.text like 'ملاحظة العميل%') >= 3 then raise exception 'too_many_notes'; end if;
  insert into public.order_notes (order_id, author_staff_id, text) values (v_order.id, null, 'ملاحظة العميل / Customer note: ' || v_text);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_inbox_notifications()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_table_name = 'complaints' then
    perform public.notify_admins('complaint',
      jsonb_build_object('ar', 'شكوى جديدة ' || new.ticket, 'en', 'New complaint ' || new.ticket),
      jsonb_build_object('ar', left(new.description, 120), 'en', left(new.description, 120)),
      '/complaints/' || new.id);
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.app_order_ledger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_rate numeric;
  v_commission numeric;
begin
  if tg_op = 'INSERT' then
    if new.source <> 'app' then return new; end if;
    select coalesce(b.commission_rate,
                    (select (s.value ->> 'defaultPct')::numeric from public.platform_settings s where s.key = 'commission'),
                    7)
      into v_rate
    from public.businesses b where b.id = new.business_id;
    v_commission := round(new.total * v_rate / 100, 2);
    insert into public.transactions (id, order_id, business_id, gross, commission_rate, commission, net_to_wash, date, status)
    values ('txn_' || new.id, new.id, new.business_id, new.total, v_rate, v_commission, new.total - v_commission, new.scheduled_at, 'pending')
    on conflict (order_id) do nothing;
  elsif new.status in ('cancelled', 'no_show') and old.status is distinct from new.status then
    delete from public.transactions where order_id = new.id and status = 'pending';
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_logs_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  raise exception 'audit_logs is append-only (% is not allowed)', tg_op
    using errcode = 'insufficient_privilege';
end;
$function$
;

CREATE OR REPLACE FUNCTION public.branch_money(p_branch_id text, OUT currency text, OUT decimals integer)
 RETURNS record
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select c.currency, c.currency_decimals::int from public.branches b join public.areas a on a.id = b.area_id join public.countries c on c.code = a.country_code where b.id = p_branch_id
$function$
;

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
$function$
;

CREATE OR REPLACE FUNCTION public.cancel_order(p_order_id text, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_cust public.customers := public._booking_customer();
  v_order public.orders%rowtype;
  v_free_min int;
  v_late boolean;
begin
  select * into v_order from public.orders where id = p_order_id and customer_id = v_cust.id for update;
  if not found then
    raise exception 'order_not_found';
  end if;
  if v_order.status not in ('pending', 'confirmed') then
    raise exception 'order_not_cancellable';
  end if;

  select free_cancel_min into v_free_min from public.branches where id = v_order.branch_id;
  v_late := v_order.scheduled_at - now() < make_interval(mins => coalesce(v_free_min, 60));

  update public.orders
  set status = 'cancelled',
      cancel_reason = left(coalesce(nullif(trim(p_reason), ''), 'ألغاه العميل — Cancelled by the customer'), 500),
      cancelled_at = now(),
      cancelled_by_type = 'customer',
      cancelled_by_id = v_cust.id,
      updated_at = now()
  where id = v_order.id;

  insert into public.order_events (order_id, status, actor_type, actor_id)
  values (v_order.id, 'cancelled', 'customer', v_cust.id);

  return public._order_json(v_order.id) || jsonb_build_object('late_cancel', v_late);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.clean_demo_auth_users()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  DELETE FROM auth.users WHERE email LIKE '%@carzen.demo';
END;
$function$
;

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
$function$
;

CREATE OR REPLACE FUNCTION public.create_order(p_branch_id text, p_vehicle_id text, p_primary_service_id text, p_scheduled_at timestamp with time zone, p_addon_service_ids text[] DEFAULT '{}'::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_cust public.customers := public._booking_customer();
  v_branch public.branches%rowtype;
  v_vehicle public.vehicles%rowtype;
  v_primary public.services%rowtype;
  v_addons public.services[];
  v_addon_ids text[] := array(select distinct unnest(coalesce(p_addon_service_ids, '{}')));
  v_subtotal numeric;
  v_duration int;
  v_offer_id text;
  v_offer_type public.discount_type;
  v_offer_value numeric;
  v_discount numeric := 0;
  v_order public.orders%rowtype;
  v_status public.order_status;
begin
  select b.* into v_branch
  from public.branches b
  join public.businesses biz on biz.id = b.business_id
  where b.id = p_branch_id and b.active and biz.status = 'active';
  if not found then
    raise exception 'branch_unavailable';
  end if;

  select * into v_vehicle from public.vehicles where id = p_vehicle_id and customer_id = v_cust.id;
  if not found then
    raise exception 'vehicle_not_found';
  end if;

  select * into v_primary
  from public.services
  where id = p_primary_service_id and branch_id = v_branch.id and type = 'primary' and active;
  if not found then
    raise exception 'service_not_found';
  end if;

  select coalesce(array_agg(s order by array_position(v_addon_ids, s.id)), '{}') into v_addons
  from public.services s
  where s.id = any (v_addon_ids) and s.branch_id = v_branch.id and s.type = 'addon' and s.active;
  if cardinality(v_addons) <> cardinality(v_addon_ids) then
    raise exception 'invalid_addon';
  end if;

  select v_primary.price + coalesce(sum(a.price), 0),
         v_primary.duration_min + coalesce(sum(a.duration_min), 0)::int
    into v_subtotal, v_duration
  from unnest(v_addons) as a;

  -- Best live offer for this branch; applies to the primary service only (same rule as the partner
  -- portal). Live = inside its dates and not draft/disabled. No categories = every service.
  select o.id, o.discount_type, o.discount_value,
         case when o.discount_type = 'percent'
              then round(v_primary.price * o.discount_value / 100.0)
              else least(o.discount_value, v_primary.price) end as amount
    into v_offer_id, v_offer_type, v_offer_value, v_discount
  from public.offers o
  join public.offer_branches ob on ob.offer_id = o.id and ob.branch_id = v_branch.id
  where o.status not in ('draft', 'disabled')
    and now() >= o.starts_at and now() < o.ends_at
    and (not exists (select 1 from public.offer_categories oc where oc.offer_id = o.id)
         or exists (select 1 from public.offer_categories oc where oc.offer_id = o.id and oc.category_id = v_primary.category_id))
  order by amount desc, o.id
  limit 1;
  v_discount := greatest(coalesce(v_discount, 0), 0);

  -- Serialize bookings per branch so two customers cannot take the last seat.
  perform pg_advisory_xact_lock(hashtext('washup_slot:' || v_branch.id));
  perform public._assert_slot_bookable(v_branch, p_scheduled_at, v_duration);
  -- One booking per car at a time, at most 3 upcoming per customer.
  perform pg_advisory_xact_lock(hashtext('washup_customer:' || v_cust.id));
  perform public._assert_customer_can_book(v_cust.id, v_vehicle.id, p_scheduled_at, v_duration);

  v_status := case when v_branch.auto_confirm then 'confirmed' else 'pending' end;

  insert into public.orders (
    number, source, customer_id, vehicle_id, plate, business_id, branch_id,
    offer_id, subtotal, discount_amount, discount_pct, discount_reason, total,
    duration_min, scheduled_at, status, payment_status
  ) values (
    public.next_order_number('app'), 'app', v_cust.id, v_vehicle.id, v_vehicle.plate,
    v_branch.business_id, v_branch.id,
    case when v_discount > 0 then v_offer_id end,
    v_subtotal,
    case when v_discount > 0 then v_discount end,
    case when v_discount > 0 and v_offer_type = 'percent' then v_offer_value end,
    case when v_discount > 0 then 'offer' end,
    v_subtotal - v_discount,
    v_duration, p_scheduled_at, v_status, 'pending'
  )
  returning * into v_order;

  insert into public.order_items (order_id, service_id, name, type, price, duration_min, position)
  select v_order.id, s.id, s.name, s.type, s.price, s.duration_min, s.pos
  from (
    select v_primary.id, v_primary.name, v_primary.type, v_primary.price, v_primary.duration_min, 0 as pos
    union all
    select t.id, t.name, t.type, t.price, t.duration_min, t.ordinality::int
    from unnest(v_addons) with ordinality as t
  ) as s(id, name, type, price, duration_min, pos);

  insert into public.order_events (order_id, status, actor_type, actor_id)
  values (v_order.id, 'pending', 'customer', v_cust.id);
  if v_status = 'confirmed' then
    insert into public.order_events (order_id, status, actor_type, actor_id)
    values (v_order.id, 'confirmed', 'system', 'auto_confirm');
  end if;

  return public._order_json(v_order.id);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.current_active_customer_id()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select c.id from public.customers c
  where c.user_id = (select auth.uid()) and c.status = 'active'
  limit 1
$function$
;

CREATE OR REPLACE FUNCTION public.current_customer_id()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT id FROM public.customers WHERE user_id = (SELECT auth.uid()) LIMIT 1;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_my_account()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := (select auth.uid());
  v_customer_id text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  select id into v_customer_id from public.customers where user_id = v_uid limit 1;

  if v_customer_id is not null then
    if exists (
      select 1 from public.orders
      where customer_id = v_customer_id
        and status in ('pending', 'confirmed', 'waiting', 'in_service')
    ) then
      raise exception 'active_booking';
    end if;

    delete from public.customers where id = v_customer_id;
  end if;

  delete from auth.users where id = v_uid;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.discover_branches(p_lat double precision, p_lng double precision, p_country text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_max_km double precision DEFAULT NULL::double precision, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0, p_query text DEFAULT NULL::text)
 RETURNS TABLE(branch jsonb, km double precision, from_price numeric, country_code text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  WITH q AS (SELECT nullif(trim(p_query), '') AS text),
  b AS (
    SELECT br.*, a.country_code AS area_country,
      6371 * 2 * asin(sqrt(
        power(sin(radians(br.lat - p_lat) / 2), 2)
        + cos(radians(p_lat)) * cos(radians(br.lat)) * power(sin(radians(br.lng - p_lng) / 2), 2)
      )) AS dist
    FROM public.branches br
    JOIN public.areas a ON a.id = br.area_id
    CROSS JOIN q
    WHERE br.active
      AND (p_country IS NULL OR a.country_code = p_country)
      AND (q.text IS NULL
        OR br.name ->> 'ar' ILIKE '%' || q.text || '%' OR br.name ->> 'en' ILIKE '%' || q.text || '%'
        OR a.name ->> 'ar' ILIKE '%' || q.text || '%' OR a.name ->> 'en' ILIKE '%' || q.text || '%')
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
$function$
;

CREATE OR REPLACE FUNCTION public.format_booking_time(p_at timestamp with time zone, p_lang text DEFAULT 'ar'::text)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  -- Kept for callers without a branch: Cairo, as before.
  SELECT public.format_booking_time(p_at, p_lang, 'Africa/Cairo');
$function$
;

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
$function$
;

CREATE OR REPLACE FUNCTION public.gen_check_in_code()
 RETURNS text
 LANGUAGE sql
 SET search_path TO ''
AS $function$
  select string_agg(substr('23456789ABCDEFGHJKLMNPQRSTUVWXYZ', 1 + floor(random() * 32)::int, 1), '')
  from generate_series(1, 5);
$function$
;

CREATE OR REPLACE FUNCTION public.gen_id(prefix text)
 RETURNS text
 LANGUAGE sql
 SET search_path TO ''
AS $function$
  select prefix || '_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 16);
$function$
;

CREATE OR REPLACE FUNCTION public.generate_settlements(p_period_start date, p_period_end date)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r record; v_id text; n int := 0;
begin
  if p_period_start is null or p_period_end is null or p_period_end < p_period_start then raise exception 'invalid_period'; end if;
  for r in
    select t.business_id, coalesce(t.currency, 'EGP') as cur, sum(t.commission) as due, array_agg(t.id) as ids
    from public.transactions t
    where t.status = 'paid' and t.payout_id is null and t.date >= p_period_start::timestamptz and t.date < (p_period_end + 1)::timestamptz
    group by 1, 2 having sum(t.commission) > 0
  loop
    insert into public.payouts (business_id, period_start, period_end, amount_due, amount_paid, status, currency) values (r.business_id, p_period_start, p_period_end, r.due, 0, 'due', r.cur) returning id into v_id;
    update public.transactions set payout_id = v_id where id = any (r.ids);
    n := n + 1;
  end loop;
  return n;
end $function$
;

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
  -- GAP-014 / GAP-025 (2026-11-25): only live businesses, sane durations.
  IF NOT public.is_business_live(v_branch.business_id) THEN RETURN; END IF;
  IF p_duration IS NULL OR p_duration < 1 OR p_duration > 720 THEN RETURN; END IF;

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
$function$
;

CREATE OR REPLACE FUNCTION public.get_support_info()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT jsonb_build_object(
    'phone', nullif(trim(value ->> 'supportPhone'), ''),
    'email', nullif(trim(value ->> 'supportEmail'), ''),
    'hours', value -> 'supportHours'
  )
  FROM public.platform_settings
  WHERE key = 'general';
$function$
;

CREATE OR REPLACE FUNCTION public.guard_customer_complaint()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_order public.orders%rowtype;
begin
  if current_user not in ('authenticated', 'anon') then return new; end if;
  new.customer_id := public.current_customer_id();
  if new.order_id is not null then
    select * into v_order from public.orders where id = new.order_id and customer_id = new.customer_id;
    if not found then raise exception 'complaint_order_not_found' using errcode = '42501'; end if;
    new.business_id := v_order.business_id;
    new.branch_id := v_order.branch_id;
  end if;
  new.status := 'open';
  new.assigned_admin_id := null;
  new.resolution := null;
  new.ticket := public.next_complaint_ticket();
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.guard_customer_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if current_user not in ('authenticated', 'anon') then return new; end if;
  new.id := old.id;
  new.customer_id := old.customer_id;
  new.type := old.type;
  new.title := old.title;
  new.body := old.body;
  new.href := old.href;
  new.order_id := old.order_id;
  new.created_at := old.created_at;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.guard_customer_review()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_order public.orders%rowtype;
begin
  if current_user not in ('authenticated', 'anon') then return new; end if;
  if tg_op = 'INSERT' then
    select * into v_order from public.orders where id = new.order_id and customer_id = public.current_customer_id();
    if not found then raise exception 'review_order_not_found' using errcode = '42501'; end if;
    if v_order.status <> 'completed' then raise exception 'review_order_not_completed' using errcode = '42501'; end if;
    new.customer_id := v_order.customer_id;
    new.business_id := v_order.business_id;
    new.branch_id := v_order.branch_id;
    new.service_id := (select i.service_id from public.order_items i where i.order_id = v_order.id and i.type = 'primary' order by i.position limit 1);
    new.status := 'visible';
    new.hidden_reason := null;
    new.reply := null;
    new.reply_at := null;
    new.reported_by_wash := false;
    new.report_reason := null;
  else
    -- Customers edit their own words only; moderation, replies and links stay as they are.
    new.id := old.id;
    new.order_id := old.order_id;
    new.customer_id := old.customer_id;
    new.business_id := old.business_id;
    new.branch_id := old.branch_id;
    new.service_id := old.service_id;
    new.reply := old.reply;
    new.reply_at := old.reply_at;
    new.reported_by_wash := old.reported_by_wash;
    new.report_reason := old.report_reason;
    new.status := old.status;
    new.hidden_reason := old.hidden_reason;
    new.created_at := old.created_at;
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.guard_customer_row()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if current_user not in ('authenticated', 'anon') then return new; end if;
  if tg_op = 'INSERT' then
    new.user_id := auth.uid();
    new.status := 'active';
    new.status_reason := null;
  else
    new.id := old.id;
    new.user_id := old.user_id;
    new.phone := old.phone;
    new.status := old.status;
    new.status_reason := old.status_reason;
    new.created_at := old.created_at;
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.guard_order_status_transition()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if new.status is not distinct from old.status then
    return new;
  end if;
  if (old.status::text, new.status::text) in (
    ('pending', 'confirmed'), ('pending', 'cancelled'), ('pending', 'no_show'),
    ('confirmed', 'pending'), ('confirmed', 'waiting'), ('confirmed', 'cancelled'), ('confirmed', 'no_show'),
    ('waiting', 'in_service'), ('waiting', 'cancelled'), ('waiting', 'no_show'),
    ('in_service', 'completed'), ('in_service', 'cancelled')
  ) then
    return new;
  end if;
  raise exception 'invalid_status_transition: % -> %', old.status, new.status using errcode = 'P0001';
end
$function$
;

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
$function$
;

CREATE OR REPLACE FUNCTION public.is_business_live(p_business_id text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.businesses b where b.id = p_business_id and b.status = 'active');
$function$
;

CREATE OR REPLACE FUNCTION public.is_localized(value jsonb)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select value is not null
     and jsonb_typeof(value) = 'object'
     and jsonb_typeof(value -> 'ar') = 'string'
     and jsonb_typeof(value -> 'en') = 'string'
     and length(value ->> 'ar') > 0;
$function$
;

CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.staff s WHERE s.user_id = (SELECT auth.uid()))
      OR EXISTS (SELECT 1 FROM public.admin_users a WHERE a.user_id = (SELECT auth.uid()));
$function$
;

CREATE OR REPLACE FUNCTION public.next_complaint_ticket()
 RETURNS text
 LANGUAGE sql
 SET search_path TO ''
AS $function$
  select 'TK-' || nextval('public.complaint_ticket_seq')::text;
$function$
;

CREATE OR REPLACE FUNCTION public.next_order_number(src public.order_source)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  n bigint;
begin
  n := case src
         when 'app'     then nextval('public.order_number_app_seq')
         when 'walk_in' then nextval('public.order_number_walk_in_seq')
         when 'phone'   then nextval('public.order_number_phone_seq')
       end;
  return 'CZ-' || lpad(n::text, 5, '0');
end;
$function$
;

CREATE OR REPLACE FUNCTION public.normalize_plate(plate text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  -- One spelling per plate: no spaces, dashes, dots or underscores; Arabic-Indic
  -- and Persian digits as 0-9; أ إ آ → ا, ى → ي, ة → ه; Latin in capitals.
  -- Matches FormatHelper.normalizePlate in the customer app.
  select upper(translate(
    regexp_replace(coalesce(plate, ''), '[\s\-_.]', '', 'g'),
    '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹أإآىة',
    '01234567890123456789اااية'
  ));
$function$
;

CREATE OR REPLACE FUNCTION public.notify_admins(p_type public.admin_notification_type, p_title jsonb, p_body jsonb, p_href text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id text;
begin
  insert into public.admin_notifications (type, title, body, href) values (p_type, p_title, p_body, p_href) returning id into v_id;
  perform public.panel_push('admin', v_id);
end $function$
;

CREATE OR REPLACE FUNCTION public.notify_customer_notification_push()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_url text;
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_url FROM vault.decrypted_secrets WHERE name = 'send_push_url';
  SELECT decrypted_secret INTO v_secret FROM vault.decrypted_secrets WHERE name = 'send_push_webhook_secret';
  IF v_url IS NULL OR v_secret IS NULL THEN
    RETURN NULL;
  END IF;

  PERFORM net.http_post(
    url := v_url,
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(NEW),
      'old_record', NULL
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', v_secret
    ),
    timeout_milliseconds := 10000
  );
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  -- A push problem must never roll back the notification itself.
  RAISE WARNING 'send-push webhook for % failed: %', NEW.id, SQLERRM;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_order_live_push()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_url text;
  v_secret text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.live_booking_devices WHERE order_id = NEW.id) THEN
    RETURN NULL;
  END IF;
  SELECT decrypted_secret INTO v_url FROM vault.decrypted_secrets WHERE name = 'send_push_url';
  SELECT decrypted_secret INTO v_secret FROM vault.decrypted_secrets WHERE name = 'send_push_webhook_secret';
  IF v_url IS NULL OR v_secret IS NULL THEN
    RETURN NULL;
  END IF;

  PERFORM net.http_post(
    url := v_url,
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', jsonb_build_object('id', NEW.id, 'status', NEW.status),
      'old_record', jsonb_build_object('id', OLD.id, 'status', OLD.status)
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', v_secret
    ),
    timeout_milliseconds := 10000
  );
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  -- A push problem must never roll back the status change itself.
  RAISE WARNING 'live booking push for % failed: %', NEW.id, SQLERRM;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_wash(p_business text, p_branch text, p_type public.vendor_notification_type, p_title text, p_body text, p_href text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id text;
begin
  if coalesce((select (s.notification_prefs ->> p_type::text)::boolean from public.business_settings s where s.business_id = p_business), true) is false then
    return;
  end if;
  insert into public.vendor_notifications (business_id, branch_id, type, title, body, href)
  values (p_business, p_branch, p_type, jsonb_build_object('ar', p_title, 'en', p_title), jsonb_build_object('ar', p_body, 'en', p_body), p_href)
  returning id into v_id;
  perform public.panel_push('vendor', v_id);
end $function$
;

CREATE OR REPLACE FUNCTION public.order_ledger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_rate numeric; v_cur text; v_dec int; v_comm numeric;
begin
  select m.currency, m.decimals into v_cur, v_dec from public.branch_money(new.branch_id) m;
  v_dec := coalesce(v_dec, 2);
  if tg_op = 'INSERT' then
    if new.status in ('cancelled', 'no_show') then return new; end if;
    select coalesce(b.commission_rate, (select (s.value ->> 'defaultPct')::numeric from public.platform_settings s where s.key = 'commission'), 7) into v_rate from public.businesses b where b.id = new.business_id;
    v_comm := round(new.total * coalesce(v_rate, 7) / 100, v_dec);
    insert into public.transactions (id, order_id, business_id, gross, commission_rate, commission, net_to_wash, date, status, currency)
    values ('txn_' || new.id, new.id, new.business_id, new.total, coalesce(v_rate, 7), v_comm, new.total - v_comm, new.scheduled_at, 'pending', coalesce(v_cur, 'EGP'))
    on conflict (order_id) do nothing;
  elsif new.status in ('cancelled', 'no_show') and old.status is distinct from new.status then
    delete from public.transactions where order_id = new.id and status = 'pending';
  elsif new.total is distinct from old.total then
    update public.transactions t set gross = new.total, commission = round(new.total * t.commission_rate / 100, v_dec), net_to_wash = new.total - round(new.total * t.commission_rate / 100, v_dec) where t.order_id = new.id and t.status = 'pending';
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.panel_push(p_target text, p_id text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets
  where name = case p_target when 'admin' then 'panel_push_admin_url' else 'panel_push_vendor_url' end;
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'panel_push_secret';
  if v_url is null or v_secret is null then return; end if;
  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('id', p_id),
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-webhook-secret', v_secret),
    timeout_milliseconds := 10000
  );
exception when others then
  raise warning 'panel push % % failed: %', p_target, p_id, sqlerrm;
end $function$
;

CREATE OR REPLACE FUNCTION public.push_devices_take_over_token()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  DELETE FROM public.push_devices
  WHERE token = NEW.token
    AND user_id IS DISTINCT FROM NEW.user_id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.quote_order(p_branch_id text, p_primary_service_id text, p_addon_service_ids text[] DEFAULT '{}'::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_branch public.branches%rowtype; v_primary public.services%rowtype; v_addons public.services[];
  v_addon_ids text[] := array(select distinct unnest(coalesce(p_addon_service_ids, '{}')));
  v_subtotal numeric; v_duration int; v_offer_id text; v_offer_type public.discount_type; v_offer_value numeric; v_discount numeric := 0;
begin
  select b.* into v_branch from public.branches b join public.businesses biz on biz.id = b.business_id where b.id = p_branch_id and b.active and biz.status = 'active';
  if not found then raise exception 'branch_unavailable'; end if;
  select * into v_primary from public.services where id = p_primary_service_id and branch_id = v_branch.id and type = 'primary' and active;
  if not found then raise exception 'service_not_found'; end if;
  select coalesce(array_agg(s order by array_position(v_addon_ids, s.id)), '{}') into v_addons from public.services s where s.id = any (v_addon_ids) and s.branch_id = v_branch.id and s.type = 'addon' and s.active;
  if cardinality(v_addons) <> cardinality(v_addon_ids) then raise exception 'invalid_addon'; end if;
  select v_primary.price + coalesce(sum(a.price), 0), v_primary.duration_min + coalesce(sum(a.duration_min), 0)::int into v_subtotal, v_duration from unnest(v_addons) as a;
  select o.id, o.discount_type, o.discount_value,
         case when o.discount_type = 'percent' then round(v_primary.price * o.discount_value / 100.0) else least(o.discount_value, v_primary.price) end as amount
    into v_offer_id, v_offer_type, v_offer_value, v_discount
  from public.offers o join public.offer_branches ob on ob.offer_id = o.id and ob.branch_id = v_branch.id
  where o.status not in ('draft', 'disabled') and now() >= o.starts_at and now() < o.ends_at
    and (not exists (select 1 from public.offer_categories oc where oc.offer_id = o.id) or exists (select 1 from public.offer_categories oc where oc.offer_id = o.id and oc.category_id = v_primary.category_id))
  order by amount desc, o.id limit 1;
  v_discount := greatest(coalesce(v_discount, 0), 0);
  return jsonb_build_object('subtotal', v_subtotal, 'discount', v_discount, 'total', v_subtotal - v_discount,
    'offer_id', case when v_discount > 0 then v_offer_id end,
    'discount_pct', case when v_discount > 0 and v_offer_type = 'percent' then v_offer_value end, 'duration_min', v_duration);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_offer_statuses()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_n integer;
begin
  update public.offers o
  set status = s.live
  from (
    select id, (case when ends_at < now() then 'expired' when starts_at > now() then 'scheduled' else 'active' end)::public.offer_status as live
    from public.offers where status not in ('draft', 'disabled')
  ) s
  where o.id = s.id and o.status <> s.live;
  get diagnostics v_n = row_count;
  return v_n;
end $function$
;

CREATE OR REPLACE FUNCTION public.refresh_review_ratings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  b_ids   text[];
  biz_ids text[];
begin
  if tg_op = 'DELETE' then
    b_ids := array[old.branch_id];   biz_ids := array[old.business_id];
  elsif tg_op = 'UPDATE' then
    b_ids := array[old.branch_id, new.branch_id];   biz_ids := array[old.business_id, new.business_id];
  else
    b_ids := array[new.branch_id];   biz_ids := array[new.business_id];
  end if;

  update public.branches br
     set rating = coalesce(s.avg_stars, 0), review_count = coalesce(s.cnt, 0)
    from (select b.id,
                 round(avg(r.stars)::numeric, 1) as avg_stars,
                 count(r.id)::int as cnt
            from public.branches b
            left join public.reviews r on r.branch_id = b.id and r.status = 'visible'
           where b.id = any (b_ids)
           group by b.id) s
   where br.id = s.id;

  update public.businesses bz
     set rating = coalesce(s.avg_stars, 0)
    from (select z.id, round(avg(r.stars)::numeric, 1) as avg_stars
            from public.businesses z
            left join public.reviews r on r.business_id = z.id and r.status = 'visible'
           where z.id = any (biz_ids)
           group by z.id) s
   where bz.id = s.id;

  return null;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.reschedule_order(p_order_id text, p_scheduled_at timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_cust public.customers := public._booking_customer();
  v_order public.orders%rowtype;
  v_branch public.branches%rowtype;
  v_reconfirm boolean;
begin
  select * into v_order from public.orders where id = p_order_id and customer_id = v_cust.id for update;
  if not found then
    raise exception 'order_not_found';
  end if;
  if v_order.status not in ('pending', 'confirmed') then
    raise exception 'order_not_reschedulable';
  end if;
  if v_order.scheduled_at = p_scheduled_at then
    return public._order_json(v_order.id);
  end if;

  select * into v_branch from public.branches where id = v_order.branch_id;
  -- GAP-014 (2026-11-25): no moves into a suspended wash or an inactive branch.
  if not v_branch.active or not public.is_business_live(v_branch.business_id) then
    raise exception 'branch_unavailable';
  end if;
  perform pg_advisory_xact_lock(hashtext('washup_slot:' || v_branch.id));
  perform public._assert_slot_bookable(v_branch, p_scheduled_at, v_order.duration_min, v_order.id);
  perform pg_advisory_xact_lock(hashtext('washup_customer:' || v_cust.id));
  perform public._assert_customer_can_book(v_cust.id, v_order.vehicle_id, p_scheduled_at, v_order.duration_min, v_order.id);

  v_reconfirm := v_order.status = 'confirmed' and not v_branch.auto_confirm;

  update public.orders
  set scheduled_at = p_scheduled_at,
      status = case when v_reconfirm then 'pending'::public.order_status else status end,
      updated_at = now()
  where id = v_order.id;

  if v_reconfirm then
    insert into public.order_events (order_id, status, actor_type, actor_id)
    values (v_order.id, 'pending', 'customer', v_cust.id);
  end if;

  return public._order_json(v_order.id);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
  tbl name;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        SELECT c.relname INTO tbl FROM pg_catalog.pg_class c WHERE c.oid = cmd.objid;
        EXECUTE format('alter table if exists %I.%I enable row level security', cmd.schema_name, tbl);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.send_push_config()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT coalesce(jsonb_object_agg(name, decrypted_secret), '{}'::jsonb)
  FROM vault.decrypted_secrets
  WHERE name IN ('send_push_webhook_secret', 'firebase_service_account');
$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_customer_profile(p_phone text, p_name text DEFAULT NULL::text, p_locale text DEFAULT 'ar'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := (select auth.uid());
  v_cust public.customers%rowtype;
  v_verified text;
  v_owner_verified text;
  v_input text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
  v_phone text;
  v_name text := nullif(trim(coalesce(p_name, '')), '');
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;
  if v_name is not null and length(v_name) < 2 then
    v_name := null;
  end if;

  -- 1. Already linked: refresh profile fields only (never phone or owner).
  select * into v_cust from public.customers where user_id = v_uid limit 1;
  if found then
    update public.customers
    set name = coalesce(v_name, name),
        locale = coalesce(p_locale, locale),
        last_active_at = now(),
        updated_at = now()
    where id = v_cust.id
    returning * into v_cust;
    return to_jsonb(v_cust);
  end if;

  -- The only phone we trust is the one Supabase Auth verified by SMS code.
  select nullif(regexp_replace(coalesce(u.phone, ''), '\D', '', 'g'), '')
    into v_verified
  from auth.users u
  where u.id = v_uid and u.phone_confirmed_at is not null;

  if v_verified is not null then
    -- 2. Verified phone: claim the customer with this number, unless another
    --    account has verified the same number too.
    select * into v_cust
    from public.customers
    where regexp_replace(phone, '\D', '', 'g') = v_verified
    order by (user_id is null) desc, created_at
    limit 1
    for update;

    if found then
      if v_cust.user_id is not null then
        select nullif(regexp_replace(coalesce(u.phone, ''), '\D', '', 'g'), '')
          into v_owner_verified
        from auth.users u
        where u.id = v_cust.user_id and u.phone_confirmed_at is not null;
        if v_owner_verified = v_verified then
          raise exception 'phone_in_use';
        end if;
      end if;
      update public.customers
      set user_id = v_uid,
          name = coalesce(v_name, name),
          locale = coalesce(p_locale, locale),
          last_active_at = now(),
          updated_at = now()
      where id = v_cust.id
      returning * into v_cust;
      return to_jsonb(v_cust);
    end if;
    v_phone := '+' || v_verified;
  else
    -- 3. No verified phone (Google/Apple sign-in): never link by phone, and do
    --    not let an unverified number shadow an existing customer.
    if v_input = '' then
      raise exception 'phone_required';
    end if;
    if exists (select 1 from public.customers where regexp_replace(phone, '\D', '', 'g') = v_input) then
      raise exception 'phone_in_use';
    end if;
    v_phone := '+' || v_input;
  end if;

  -- 4. Create a new customer once we have a name.
  if v_name is null then
    return null;
  end if;

  insert into public.customers (id, user_id, name, phone, locale, status, last_active_at)
  values (public.gen_id('cu'), v_uid, v_name, v_phone, coalesce(p_locale, 'ar'), 'active', now())
  returning * into v_cust;

  return to_jsonb(v_cust);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.vendor_panel_app_phone_confirmed(p_user_id text, p_phone text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from auth.users u
    where u.id = nullif(p_user_id, '')::uuid and u.phone_confirmed_at is not null
      and '+' || ltrim(u.phone, '+') = p_phone)
$function$
;

CREATE OR REPLACE FUNCTION public.vendor_panel_business_branches()
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(array_agg(b.id::text), '{}'::text[])
  from public.branches b
  where b.business_id::text = public.vendor_panel_business_id()
$function$
;

CREATE OR REPLACE FUNCTION public.vendor_panel_business_id()
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select nullif(current_setting('app.business_id', true), '')
$function$
;

CREATE OR REPLACE FUNCTION public.vendor_panel_owns_offer(p_offer_id text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.offers o
    where o.id::text = p_offer_id and o.scope::text = 'wash'
      and o.business_id::text = public.vendor_panel_business_id())
$function$
;

CREATE OR REPLACE FUNCTION public.vendor_panel_staff_id()
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select nullif(current_setting('app.staff_id', true), '')
$function$
;

CREATE OR REPLACE FUNCTION public.vendor_panel_staff_phone_taken(p_phone text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (select 1 from public.staff s where s.phone = p_phone)
$function$
;

CREATE OR REPLACE FUNCTION public.vendor_panel_user_id()
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  select nullif(current_setting('app.user_id', true), '')
$function$
;

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
end $function$
;

-- ==== Sequences (4) ====

create sequence if not exists public.complaint_ticket_seq as bigint increment by 1 minvalue 1 maxvalue 9223372036854775807 start with 1001 cache 1;

create sequence if not exists public.order_number_app_seq as bigint increment by 1 minvalue 10001 maxvalue 999999999 start with 10001 cache 1;

create sequence if not exists public.order_number_phone_seq as bigint increment by 1 minvalue 30001 maxvalue 999999999 start with 30001 cache 1;

create sequence if not exists public.order_number_walk_in_seq as bigint increment by 1 minvalue 20001 maxvalue 999999999 start with 20001 cache 1;

-- ==== Tables (45) ====

create table public.admin_notification_reads (
  notification_id text not null,
  admin_id text not null,
  read_at timestamp with time zone default now() not null
);

create table public.admin_notifications (
  id text default public.gen_id('an'::text) not null,
  type public.admin_notification_type not null,
  title jsonb not null,
  body jsonb not null,
  href text default '/'::text not null,
  read boolean default false not null,
  created_at timestamp with time zone default now() not null
);

create table public.admin_role_permissions (
  role public.admin_role not null,
  permission_key text not null,
  level public.permission_level default 'none'::public.permission_level not null,
  updated_at timestamp with time zone default now() not null
);

create table public.admin_users (
  id text default public.gen_id('adm'::text) not null,
  user_id uuid,
  name text not null,
  email text not null,
  role public.admin_role not null,
  status public.admin_status default 'active'::public.admin_status not null,
  last_login_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.amenities (
  id text not null,
  name jsonb not null,
  active boolean default true not null,
  sort_order smallint default 0 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.areas (
  id text not null,
  name jsonb not null,
  active boolean default true not null,
  sort_order smallint default 0 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  country_code text default 'EG'::text not null,
  lat double precision,
  lng double precision
);

create table public.audit_logs (
  id text default public.gen_id('aud'::text) not null,
  actor_type public.actor_type not null,
  actor_id text not null,
  actor_name text,
  action text not null,
  entity text not null,
  entity_id text not null,
  branch_id text,
  old_value text,
  new_value text,
  reason text,
  at timestamp with time zone default now() not null
);

create table public.branch_amenities (
  branch_id text not null,
  amenity_id text not null
);

create table public.branch_blocked_slots (
  id text default public.gen_id('blk'::text) not null,
  branch_id text not null,
  starts_at timestamp with time zone not null,
  ends_at timestamp with time zone not null,
  reason text not null,
  created_by text,
  created_at timestamp with time zone default now() not null
);

create table public.branch_photos (
  id text default public.gen_id('bph'::text) not null,
  branch_id text not null,
  storage_path text not null,
  "position" smallint default 0 not null,
  created_at timestamp with time zone default now() not null
);

create table public.branch_shares (
  id uuid default gen_random_uuid() not null,
  branch_id text not null,
  user_id text,
  platform text default 'native_share'::text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table public.branch_working_hours (
  branch_id text not null,
  weekday smallint not null,
  opens_at time without time zone not null,
  closes_at time without time zone not null,
  closed boolean default false not null
);

create table public.branches (
  id text default public.gen_id('br'::text) not null,
  business_id text not null,
  name jsonb not null,
  area_id text not null,
  address jsonb not null,
  lat numeric(9,6) not null,
  lng numeric(9,6) not null,
  phone text not null,
  capacity smallint not null,
  active boolean default true not null,
  featured boolean default false not null,
  auto_confirm boolean default false not null,
  slot_interval_min smallint default 30 not null,
  lead_time_min smallint default 60 not null,
  max_advance_days smallint default 7 not null,
  free_cancel_min smallint default 120 not null,
  no_show_grace_min smallint default 15 not null,
  reminder_min smallint default 60 not null,
  rating numeric(2,1) default 0 not null,
  review_count integer default 0 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.business_settings (
  business_id text not null,
  manager_can_edit_services boolean default false not null,
  contact_phone text,
  contact_email text,
  notification_prefs jsonb default '{}'::jsonb not null,
  updated_at timestamp with time zone default now() not null
);

create table public.businesses (
  id text default public.gen_id('biz'::text) not null,
  name jsonb not null,
  owner_staff_id text,
  status public.business_status default 'pending'::public.business_status not null,
  status_reason text,
  commission_rate numeric(5,2),
  rating numeric(2,1) default 0 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.complaint_notes (
  id text default public.gen_id('cnote'::text) not null,
  complaint_id text not null,
  author_admin_id text,
  text text not null,
  created_at timestamp with time zone default now() not null
);

create table public.complaints (
  id text default public.gen_id('cmp'::text) not null,
  ticket text default public.next_complaint_ticket() not null,
  customer_id text not null,
  business_id text not null,
  branch_id text not null,
  order_id text,
  category public.complaint_category not null,
  description text not null,
  status public.complaint_status default 'open'::public.complaint_status not null,
  assigned_admin_id text,
  resolution text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.countries (
  code text not null,
  name jsonb not null,
  currency text not null,
  currency_symbol jsonb not null,
  currency_decimals smallint default 2 not null,
  timezone text not null,
  dial_code text not null,
  lat double precision not null,
  lng double precision not null,
  active boolean default true not null,
  sort_order integer default 0 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.customer_favorites (
  customer_id text not null,
  branch_id text not null,
  created_at timestamp with time zone default now() not null
);

create table public.customer_notifications (
  id text default public.gen_id('cn'::text) not null,
  customer_id text not null,
  type text not null,
  title jsonb not null,
  body jsonb not null,
  href text default '/'::text not null,
  order_id text,
  read boolean default false not null,
  created_at timestamp with time zone default now() not null
);

create table public.customers (
  id text default public.gen_id('cu'::text) not null,
  user_id uuid,
  name text not null,
  phone text not null,
  status public.account_status default 'active'::public.account_status not null,
  status_reason text,
  last_active_at timestamp with time zone default now() not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  locale text default 'ar'::text not null,
  notify_reminders boolean default true not null,
  notify_offers boolean default true not null
);

create table public.day_closings (
  id text default public.gen_id('dc'::text) not null,
  branch_id text not null,
  date date not null,
  expected_cash numeric(10,2) default 0 not null,
  expected_card numeric(10,2) default 0 not null,
  expected_online numeric(10,2) default 0 not null,
  actual_cash numeric(10,2) default 0 not null,
  actual_card numeric(10,2) default 0 not null,
  actual_online numeric(10,2) default 0 not null,
  difference numeric(10,2) generated always as ((((actual_cash + actual_card) + actual_online) - ((expected_cash + expected_card) + expected_online))) stored,
  reason text,
  orders_locked integer default 0 not null,
  closed_by text not null,
  closed_at timestamp with time zone default now() not null
);

create table public.live_booking_devices (
  id uuid default gen_random_uuid() not null,
  order_id text not null,
  user_id uuid default auth.uid() not null,
  platform text not null,
  fcm_token text not null,
  activity_token text,
  locale text default 'ar'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.offer_branches (
  offer_id text not null,
  branch_id text not null
);

create table public.offer_categories (
  offer_id text not null,
  category_id text not null
);

create table public.offers (
  id text default public.gen_id('of'::text) not null,
  scope public.offer_scope not null,
  business_id text,
  title jsonb not null,
  description jsonb not null,
  discount_type public.discount_type not null,
  discount_value numeric(10,2) not null,
  starts_at timestamp with time zone not null,
  ends_at timestamp with time zone not null,
  status public.offer_status default 'draft'::public.offer_status not null,
  featured boolean default false not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.order_events (
  id text default public.gen_id('oev'::text) not null,
  order_id text not null,
  status public.order_status not null,
  actor_type public.actor_type not null,
  actor_id text not null,
  at timestamp with time zone default now() not null
);

create table public.order_items (
  id text default public.gen_id('oi'::text) not null,
  order_id text not null,
  service_id text,
  name jsonb not null,
  type public.service_type not null,
  price numeric(10,2) not null,
  duration_min smallint not null,
  "position" smallint default 0 not null
);

create table public.order_notes (
  id text default public.gen_id('onote'::text) not null,
  order_id text not null,
  author_staff_id text,
  text text not null,
  created_at timestamp with time zone default now() not null
);

create table public.orders (
  id text default public.gen_id('ord'::text) not null,
  number text not null,
  code text default public.gen_check_in_code() not null,
  source public.order_source not null,
  customer_id text,
  vehicle_id text,
  plate text not null,
  business_id text not null,
  branch_id text not null,
  offer_id text,
  subtotal numeric(10,2) not null,
  discount_amount numeric(10,2),
  discount_pct numeric(5,2),
  discount_reason text,
  total numeric(10,2) not null,
  duration_min smallint not null,
  scheduled_at timestamp with time zone not null,
  status public.order_status default 'pending'::public.order_status not null,
  payment_status public.order_payment_status default 'pending'::public.order_payment_status not null,
  payment_method public.payment_method,
  assigned_staff_id text,
  cancel_reason text,
  cancelled_by_type public.actor_type,
  cancelled_by_id text,
  cancelled_at timestamp with time zone,
  flag text,
  closed_in_day_id text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  plate_normalized text generated always as (public.normalize_plate(plate)) stored
);

create table public.payments (
  id text default public.gen_id('pay'::text) not null,
  order_id text not null,
  amount numeric(10,2) not null,
  method public.payment_method not null,
  collected_by text,
  collected_at timestamp with time zone default now() not null,
  status public.payment_status default 'paid'::public.payment_status not null,
  created_at timestamp with time zone default now() not null
);

create table public.payouts (
  id text default public.gen_id('po'::text) not null,
  business_id text not null,
  period_start date not null,
  period_end date not null,
  amount_due numeric(12,2) not null,
  amount_paid numeric(12,2) default 0 not null,
  status public.payout_status default 'due'::public.payout_status not null,
  reference text,
  paid_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  currency text
);

create table public.platform_settings (
  key text not null,
  value jsonb not null,
  updated_at timestamp with time zone default now() not null,
  updated_by text
);

create table public.push_devices (
  id text default public.gen_id('dev'::text) not null,
  user_id uuid not null,
  app text not null,
  platform text not null,
  token text not null,
  app_version text,
  last_seen_at timestamp with time zone default now() not null,
  created_at timestamp with time zone default now() not null
);

create table public.reviews (
  id text default public.gen_id('rev'::text) not null,
  order_id text not null,
  customer_id text not null,
  business_id text not null,
  branch_id text not null,
  service_id text,
  stars smallint not null,
  comment jsonb not null,
  tags text[] default '{}'::text[] not null,
  reply text,
  reply_at timestamp with time zone,
  reported_by_wash boolean default false not null,
  report_reason text,
  status public.review_status default 'visible'::public.review_status not null,
  hidden_reason text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.service_categories (
  id text not null,
  name jsonb not null,
  active boolean default true not null,
  sort_order smallint default 0 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.services (
  id text default public.gen_id('svc'::text) not null,
  branch_id text not null,
  type public.service_type not null,
  category_id text not null,
  name jsonb not null,
  description jsonb,
  price numeric(10,2) not null,
  duration_min smallint not null,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.staff (
  id text default public.gen_id('st'::text) not null,
  user_id uuid,
  business_id text not null,
  branch_id text,
  name text not null,
  phone text not null,
  role public.staff_role not null,
  status public.account_status default 'active'::public.account_status not null,
  max_discount_pct smallint default 0 not null,
  permissions jsonb not null,
  joined_at timestamp with time zone default now() not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  pin_hash text
);

create table public.staff_shift_patterns (
  id text default public.gen_id('pat'::text) not null,
  staff_id text not null,
  starts_at time without time zone not null,
  ends_at time without time zone not null,
  days smallint[] not null,
  created_at timestamp with time zone default now() not null
);

create table public.staff_shifts (
  id text default public.gen_id('sh'::text) not null,
  staff_id text not null,
  branch_id text not null,
  scheduled_start timestamp with time zone not null,
  scheduled_end timestamp with time zone not null,
  actual_start timestamp with time zone,
  actual_end timestamp with time zone,
  orders_completed integer default 0 not null,
  cash_payments numeric(10,2) default 0 not null,
  card_payments numeric(10,2) default 0 not null,
  expected_cash numeric(10,2) default 0 not null,
  actual_cash numeric(10,2),
  difference numeric(10,2),
  difference_reason jsonb,
  review_status public.shift_review_status default 'open'::public.shift_review_status not null,
  review_note text,
  reviewed_by text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  opening_cash numeric(10,2) default 0 not null
);

create table public.transactions (
  id text default public.gen_id('tx'::text) not null,
  order_id text not null,
  business_id text not null,
  gross numeric(10,2) not null,
  commission_rate numeric(5,2) not null,
  commission numeric(10,2) not null,
  net_to_wash numeric(10,2) not null,
  date timestamp with time zone not null,
  status public.transaction_status default 'pending'::public.transaction_status not null,
  flag text,
  review_note text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  currency text,
  payout_id text
);

create table public.vehicles (
  id text default public.gen_id('veh'::text) not null,
  customer_id text not null,
  make text not null,
  model text not null,
  year smallint,
  color text not null,
  plate text not null,
  is_default boolean default false not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  plate_normalized text generated always as (public.normalize_plate(plate)) stored
);

create table public.vendor_notification_reads (
  notification_id text not null,
  staff_id text not null,
  read_at timestamp with time zone default now() not null
);

create table public.vendor_notifications (
  id text default public.gen_id('vn'::text) not null,
  business_id text not null,
  branch_id text,
  type public.vendor_notification_type not null,
  title jsonb not null,
  body jsonb not null,
  href text default '/'::text not null,
  read boolean default false not null,
  created_at timestamp with time zone default now() not null,
  staff_id text
);

create table public.wash_applications (
  id text default public.gen_id('app'::text) not null,
  business_name text not null,
  owner_name text not null,
  phone text not null,
  email text not null,
  area_id text not null,
  address text not null,
  lat numeric(9,6) not null,
  lng numeric(9,6) not null,
  capacity smallint not null,
  working_hours jsonb not null,
  services jsonb not null,
  documents text[] default '{}'::text[] not null,
  status public.application_status default 'pending'::public.application_status not null,
  review_note text,
  business_id text,
  submitted_at timestamp with time zone default now() not null,
  reviewed_at timestamp with time zone,
  updated_at timestamp with time zone default now() not null
);

-- ==== Primary keys, unique and check constraints (174) ====

alter table only public.admin_notification_reads add constraint admin_notification_reads_pkey PRIMARY KEY (notification_id, admin_id);

alter table only public.admin_notifications add constraint admin_notifications_body_check CHECK ((jsonb_typeof(body) = 'object'::text));

alter table only public.admin_notifications add constraint admin_notifications_title_check CHECK (public.is_localized(title));

alter table only public.admin_notifications add constraint admin_notifications_pkey PRIMARY KEY (id);

alter table only public.admin_role_permissions add constraint admin_role_permissions_permission_key_check CHECK ((permission_key = ANY (ARRAY['dashboard'::text, 'customers'::text, 'staff'::text, 'washes'::text, 'applications'::text, 'branches'::text, 'orders'::text, 'reviews'::text, 'complaints'::text, 'offers'::text, 'finance'::text, 'reports'::text, 'notifications'::text, 'admins'::text, 'roles'::text, 'settings'::text, 'audit'::text])));

alter table only public.admin_role_permissions add constraint audit_is_never_managed CHECK ((NOT ((permission_key = 'audit'::text) AND (level = 'manage'::public.permission_level))));

alter table only public.admin_role_permissions add constraint admin_role_permissions_pkey PRIMARY KEY (role, permission_key);

alter table only public.admin_users add constraint admin_users_email_check CHECK ((email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text));

alter table only public.admin_users add constraint admin_users_name_check CHECK (((length(name) >= 2) AND (length(name) <= 80)));

alter table only public.admin_users add constraint admin_users_pkey PRIMARY KEY (id);

alter table only public.admin_users add constraint admin_users_email_key UNIQUE (email);

alter table only public.admin_users add constraint admin_users_user_id_key UNIQUE (user_id);

alter table only public.amenities add constraint amenities_name_check CHECK (public.is_localized(name));

alter table only public.amenities add constraint amenities_pkey PRIMARY KEY (id);

alter table only public.areas add constraint areas_name_check CHECK (public.is_localized(name));

alter table only public.areas add constraint areas_pkey1 PRIMARY KEY (id);

alter table only public.audit_logs add constraint audit_logs_pkey PRIMARY KEY (id);

alter table only public.branch_amenities add constraint branch_amenities_pkey PRIMARY KEY (branch_id, amenity_id);

alter table only public.branch_blocked_slots add constraint blocked_slot_range CHECK ((ends_at > starts_at));

alter table only public.branch_blocked_slots add constraint branch_blocked_slots_reason_check CHECK ((length(reason) >= 3));

alter table only public.branch_blocked_slots add constraint branch_blocked_slots_pkey PRIMARY KEY (id);

alter table only public.branch_photos add constraint branch_photos_pkey PRIMARY KEY (id);

alter table only public.branch_photos add constraint branch_photos_position_unique UNIQUE (branch_id, "position");

alter table only public.branch_shares add constraint branch_shares_pkey PRIMARY KEY (id);

alter table only public.branch_working_hours add constraint branch_working_hours_weekday_check CHECK (((weekday >= 0) AND (weekday <= 6)));

alter table only public.branch_working_hours add constraint working_hours_order CHECK ((closed OR (closes_at = '00:00:00'::time without time zone) OR (opens_at < closes_at)));

alter table only public.branch_working_hours add constraint branch_working_hours_pkey PRIMARY KEY (branch_id, weekday);

alter table only public.branches add constraint branches_address_check CHECK (public.is_localized(address));

alter table only public.branches add constraint branches_capacity_check CHECK (((capacity >= 1) AND (capacity <= 30)));

alter table only public.branches add constraint branches_free_cancel_min_check CHECK (((free_cancel_min >= 0) AND (free_cancel_min <= 1440)));

alter table only public.branches add constraint branches_lat_check CHECK (((lat >= ('-90'::integer)::numeric) AND (lat <= (90)::numeric)));

alter table only public.branches add constraint branches_lead_time_min_check CHECK (((lead_time_min >= 0) AND (lead_time_min <= 240)));

alter table only public.branches add constraint branches_lng_check CHECK (((lng >= ('-180'::integer)::numeric) AND (lng <= (180)::numeric)));

alter table only public.branches add constraint branches_max_advance_days_check CHECK (((max_advance_days >= 1) AND (max_advance_days <= 30)));

alter table only public.branches add constraint branches_name_check CHECK (public.is_localized(name));

alter table only public.branches add constraint branches_no_show_grace_min_check CHECK (((no_show_grace_min >= 5) AND (no_show_grace_min <= 120)));

alter table only public.branches add constraint branches_phone_check CHECK ((phone ~ '^\+[1-9][0-9]{7,14}$'::text));

alter table only public.branches add constraint branches_rating_check CHECK (((rating >= (0)::numeric) AND (rating <= (5)::numeric)));

alter table only public.branches add constraint branches_reminder_min_check CHECK (((reminder_min >= 5) AND (reminder_min <= 1440)));

alter table only public.branches add constraint branches_review_count_check CHECK ((review_count >= 0));

alter table only public.branches add constraint branches_slot_interval_min_check CHECK ((slot_interval_min = ANY (ARRAY[15, 20, 30, 45, 60])));

alter table only public.branches add constraint branches_pkey1 PRIMARY KEY (id);

alter table only public.business_settings add constraint business_settings_contact_phone_check CHECK ((contact_phone ~ '^\+[1-9][0-9]{7,14}$'::text));

alter table only public.business_settings add constraint business_settings_notification_prefs_check CHECK ((jsonb_typeof(notification_prefs) = 'object'::text));

alter table only public.business_settings add constraint business_settings_pkey PRIMARY KEY (business_id);

alter table only public.businesses add constraint businesses_commission_rate_check CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= (30)::numeric)));

alter table only public.businesses add constraint businesses_name_check CHECK (public.is_localized(name));

alter table only public.businesses add constraint businesses_rating_check CHECK (((rating >= (0)::numeric) AND (rating <= (5)::numeric)));

alter table only public.businesses add constraint businesses_pkey PRIMARY KEY (id);

alter table only public.complaint_notes add constraint complaint_notes_text_check CHECK (((length(text) >= 1) AND (length(text) <= 1000)));

alter table only public.complaint_notes add constraint complaint_notes_pkey PRIMARY KEY (id);

alter table only public.complaints add constraint complaints_description_check CHECK ((length(description) >= 5));

alter table only public.complaints add constraint complaints_resolution CHECK (((status <> ALL (ARRAY['resolved'::public.complaint_status, 'closed'::public.complaint_status])) OR (resolution IS NOT NULL)));

alter table only public.complaints add constraint complaints_pkey1 PRIMARY KEY (id);

alter table only public.complaints add constraint complaints_ticket_key UNIQUE (ticket);

alter table only public.countries add constraint countries_code_check CHECK ((code ~ '^[A-Z]{2}$'::text));

alter table only public.countries add constraint countries_currency_decimals_check CHECK (((currency_decimals >= 0) AND (currency_decimals <= 3)));

alter table only public.countries add constraint countries_pkey PRIMARY KEY (code);

alter table only public.customer_favorites add constraint customer_favorites_pkey PRIMARY KEY (customer_id, branch_id);

alter table only public.customer_notifications add constraint customer_notifications_body_check CHECK ((jsonb_typeof(body) = 'object'::text));

alter table only public.customer_notifications add constraint customer_notifications_title_check CHECK (public.is_localized(title));

alter table only public.customer_notifications add constraint customer_notifications_type_check CHECK ((type = ANY (ARRAY['created'::text, 'confirmed'::text, 'waiting'::text, 'in_service'::text, 'completed'::text, 'cancelled'::text, 'booking_confirmed'::text, 'booking_cancelled'::text, 'booking_reminder'::text, 'order_ready'::text, 'review_reminder'::text, 'offer'::text, 'complaint_update'::text, 'system'::text, 'reminder'::text])));

alter table only public.customer_notifications add constraint customer_notifications_pkey PRIMARY KEY (id);

alter table only public.customers add constraint customers_locale_check CHECK ((locale = ANY (ARRAY['ar'::text, 'en'::text])));

alter table only public.customers add constraint customers_name_check CHECK (((length(name) >= 2) AND (length(name) <= 80)));

alter table only public.customers add constraint customers_phone_check CHECK ((phone ~ '^\+[1-9][0-9]{7,14}$'::text));

alter table only public.customers add constraint customers_pkey1 PRIMARY KEY (id);

alter table only public.customers add constraint customers_phone_key UNIQUE (phone);

alter table only public.customers add constraint customers_user_id_key UNIQUE (user_id);

alter table only public.day_closings add constraint day_closings_orders_locked_check CHECK ((orders_locked >= 0));

alter table only public.day_closings add constraint day_closings_reason CHECK (((((actual_cash + actual_card) + actual_online) = ((expected_cash + expected_card) + expected_online)) OR (reason IS NOT NULL)));

alter table only public.day_closings add constraint day_closings_pkey PRIMARY KEY (id);

alter table only public.day_closings add constraint day_closings_once UNIQUE (branch_id, date);

alter table only public.live_booking_devices add constraint live_booking_devices_locale_check CHECK ((locale = ANY (ARRAY['ar'::text, 'en'::text])));

alter table only public.live_booking_devices add constraint live_booking_devices_platform_check CHECK ((platform = ANY (ARRAY['ios'::text, 'android'::text])));

alter table only public.live_booking_devices add constraint live_booking_devices_pkey PRIMARY KEY (id);

alter table only public.live_booking_devices add constraint live_booking_devices_order_id_fcm_token_key UNIQUE (order_id, fcm_token);

alter table only public.offer_branches add constraint offer_branches_pkey PRIMARY KEY (offer_id, branch_id);

alter table only public.offer_categories add constraint offer_categories_pkey PRIMARY KEY (offer_id, category_id);

alter table only public.offers add constraint offers_description_check CHECK ((jsonb_typeof(description) = 'object'::text));

alter table only public.offers add constraint offers_discount_value_check CHECK ((discount_value > (0)::numeric));

alter table only public.offers add constraint offers_percent_cap CHECK (((discount_type <> 'percent'::public.discount_type) OR (discount_value <= (50)::numeric)));

alter table only public.offers add constraint offers_range CHECK ((ends_at > starts_at));

alter table only public.offers add constraint offers_scope_business CHECK (((scope = 'wash'::public.offer_scope) = (business_id IS NOT NULL)));

alter table only public.offers add constraint offers_title_check CHECK (public.is_localized(title));

alter table only public.offers add constraint offers_pkey1 PRIMARY KEY (id);

alter table only public.order_events add constraint order_events_pkey PRIMARY KEY (id);

alter table only public.order_items add constraint order_items_duration_min_check CHECK ((duration_min > 0));

alter table only public.order_items add constraint order_items_name_check CHECK (public.is_localized(name));

alter table only public.order_items add constraint order_items_price_check CHECK ((price >= (0)::numeric));

alter table only public.order_items add constraint order_items_pkey PRIMARY KEY (id);

alter table only public.order_notes add constraint order_notes_text_check CHECK (((length(text) >= 1) AND (length(text) <= 500)));

alter table only public.order_notes add constraint order_notes_pkey PRIMARY KEY (id);

alter table only public.orders add constraint orders_app_has_customer CHECK (((source <> 'app'::public.order_source) OR (customer_id IS NOT NULL)));

alter table only public.orders add constraint orders_cancel_consistent CHECK (((status = 'cancelled'::public.order_status) = ((cancelled_at IS NOT NULL) AND (cancel_reason IS NOT NULL))));

alter table only public.orders add constraint orders_code_check CHECK ((length(code) = 5));

alter table only public.orders add constraint orders_discount_amount_check CHECK ((discount_amount >= (0)::numeric));

alter table only public.orders add constraint orders_discount_pct_check CHECK (((discount_pct >= (0)::numeric) AND (discount_pct <= (100)::numeric)));

alter table only public.orders add constraint orders_discount_reason CHECK (((discount_amount IS NULL) OR (discount_reason IS NOT NULL)));

alter table only public.orders add constraint orders_duration_min_check CHECK ((duration_min > 0));

alter table only public.orders add constraint orders_flag_check CHECK ((flag = 'finance_review'::text));

alter table only public.orders add constraint orders_number_check CHECK ((number ~ '^CZ-[0-9]{5}$'::text));

alter table only public.orders add constraint orders_paid_has_method CHECK (((payment_status = 'pending'::public.order_payment_status) OR (payment_method IS NOT NULL)));

alter table only public.orders add constraint orders_subtotal_check CHECK ((subtotal >= (0)::numeric));

alter table only public.orders add constraint orders_total_check CHECK ((total >= (0)::numeric));

alter table only public.orders add constraint orders_total_matches CHECK ((total = (subtotal - COALESCE(discount_amount, (0)::numeric))));

alter table only public.orders add constraint orders_pkey1 PRIMARY KEY (id);

alter table only public.orders add constraint orders_number_key UNIQUE (number);

alter table only public.payments add constraint payments_amount_check CHECK ((amount >= (0)::numeric));

alter table only public.payments add constraint payments_pkey PRIMARY KEY (id);

alter table only public.payouts add constraint payouts_amount_due_check CHECK ((amount_due >= (0)::numeric));

alter table only public.payouts add constraint payouts_amount_paid_check CHECK ((amount_paid >= (0)::numeric));

alter table only public.payouts add constraint payouts_paid_has_reference CHECK (((status = 'due'::public.payout_status) OR ((reference IS NOT NULL) AND (paid_at IS NOT NULL))));

alter table only public.payouts add constraint payouts_period CHECK ((period_end >= period_start));

alter table only public.payouts add constraint payouts_pkey PRIMARY KEY (id);

alter table only public.payouts add constraint payouts_one_per_period UNIQUE (business_id, period_start, period_end);

alter table only public.platform_settings add constraint platform_settings_key_check CHECK ((key = ANY (ARRAY['general'::text, 'booking_defaults'::text, 'legal'::text, 'notification_templates'::text, 'commission'::text])));

alter table only public.platform_settings add constraint platform_settings_pkey PRIMARY KEY (key);

alter table only public.push_devices add constraint push_devices_app_check CHECK ((app = ANY (ARRAY['customer'::text, 'employee'::text, 'partner'::text, 'admin'::text])));

alter table only public.push_devices add constraint push_devices_platform_check CHECK ((platform = ANY (ARRAY['ios'::text, 'android'::text, 'web'::text])));

alter table only public.push_devices add constraint push_devices_pkey PRIMARY KEY (id);

alter table only public.push_devices add constraint push_devices_token_key UNIQUE (token);

alter table only public.reviews add constraint reviews_comment_check CHECK ((jsonb_typeof(comment) = ANY (ARRAY['object'::text, 'string'::text])));

alter table only public.reviews add constraint reviews_hidden_reason CHECK (((status = 'visible'::public.review_status) OR (hidden_reason IS NOT NULL)));

alter table only public.reviews add constraint reviews_reply_check CHECK (((reply IS NULL) OR ((length(reply) >= 5) AND (length(reply) <= 400))));

alter table only public.reviews add constraint reviews_reply_time CHECK (((reply IS NULL) = (reply_at IS NULL)));

alter table only public.reviews add constraint reviews_report_reason CHECK (((NOT reported_by_wash) OR (report_reason IS NOT NULL)));

alter table only public.reviews add constraint reviews_stars_check CHECK (((stars >= 1) AND (stars <= 5)));

alter table only public.reviews add constraint reviews_pkey1 PRIMARY KEY (id);

alter table only public.reviews add constraint reviews_order_id_key UNIQUE (order_id);

alter table only public.service_categories add constraint service_categories_name_check CHECK (public.is_localized(name));

alter table only public.service_categories add constraint service_categories_pkey PRIMARY KEY (id);

alter table only public.services add constraint services_description_check CHECK (((description IS NULL) OR (jsonb_typeof(description) = 'object'::text)));

alter table only public.services add constraint services_duration_min_check CHECK (((duration_min >= 2) AND (duration_min <= 240)));

alter table only public.services add constraint services_name_check CHECK (public.is_localized(name));

alter table only public.services add constraint services_price_check CHECK (((price >= (10)::numeric) AND (price <= (5000)::numeric)));

alter table only public.services add constraint services_pkey1 PRIMARY KEY (id);

alter table only public.staff add constraint staff_branch_required CHECK (((role = 'owner'::public.staff_role) OR (branch_id IS NOT NULL)));

alter table only public.staff add constraint staff_max_discount_pct_check CHECK (((max_discount_pct >= 0) AND (max_discount_pct <= 100)));

alter table only public.staff add constraint staff_name_check CHECK (((length(name) >= 2) AND (length(name) <= 80)));

alter table only public.staff add constraint staff_permissions_check CHECK (((jsonb_typeof(permissions) = 'object'::text) AND (permissions ?& ARRAY['confirmBooking'::text, 'cancelOrder'::text, 'closeShift'::text, 'editServices'::text, 'refund'::text, 'collectPayment'::text, 'runService'::text, 'manageStaff'::text])));

alter table only public.staff add constraint staff_phone_check CHECK ((phone ~ '^\+[1-9][0-9]{7,14}$'::text));

alter table only public.staff add constraint staff_pin_only_for_managers CHECK (((pin_hash IS NULL) OR (role = ANY (ARRAY['owner'::public.staff_role, 'manager'::public.staff_role]))));

alter table only public.staff add constraint staff_pkey PRIMARY KEY (id);

alter table only public.staff add constraint staff_phone_key UNIQUE (phone);

alter table only public.staff add constraint staff_user_id_key UNIQUE (user_id);

alter table only public.staff_shift_patterns add constraint staff_shift_patterns_days_check CHECK ((((cardinality(days) >= 1) AND (cardinality(days) <= 7)) AND (days <@ ARRAY[(0)::smallint, (1)::smallint, (2)::smallint, (3)::smallint, (4)::smallint, (5)::smallint, (6)::smallint])));

alter table only public.staff_shift_patterns add constraint staff_shift_patterns_pkey PRIMARY KEY (id);

alter table only public.staff_shifts add constraint shift_difference_needs_reason CHECK (((COALESCE(difference, (0)::numeric) = (0)::numeric) OR (difference_reason IS NOT NULL)));

alter table only public.staff_shifts add constraint shift_range CHECK ((scheduled_end > scheduled_start));

alter table only public.staff_shifts add constraint staff_shifts_difference_reason_check CHECK (((difference_reason IS NULL) OR (jsonb_typeof(difference_reason) = 'object'::text)));

alter table only public.staff_shifts add constraint staff_shifts_opening_cash_check CHECK ((opening_cash >= (0)::numeric));

alter table only public.staff_shifts add constraint staff_shifts_orders_completed_check CHECK ((orders_completed >= 0));

alter table only public.staff_shifts add constraint staff_shifts_pkey PRIMARY KEY (id);

alter table only public.transactions add constraint transactions_commission_check CHECK ((commission >= (0)::numeric));

alter table only public.transactions add constraint transactions_commission_rate_check CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= (30)::numeric)));

alter table only public.transactions add constraint transactions_flag_check CHECK ((flag = 'discrepancy'::text));

alter table only public.transactions add constraint transactions_gross_check CHECK ((gross >= (0)::numeric));

alter table only public.transactions add constraint transactions_net CHECK ((net_to_wash = (gross - commission)));

alter table only public.transactions add constraint transactions_pkey PRIMARY KEY (id);

alter table only public.transactions add constraint transactions_order_id_key UNIQUE (order_id);

alter table only public.vehicles add constraint vehicles_year_check CHECK (((year >= 1950) AND (year <= 2100)));

alter table only public.vehicles add constraint vehicles_pkey1 PRIMARY KEY (id);

alter table only public.vendor_notification_reads add constraint vendor_notification_reads_pkey PRIMARY KEY (notification_id, staff_id);

alter table only public.vendor_notifications add constraint vendor_notifications_body_check CHECK ((jsonb_typeof(body) = 'object'::text));

alter table only public.vendor_notifications add constraint vendor_notifications_title_check CHECK (public.is_localized(title));

alter table only public.vendor_notifications add constraint vendor_notifications_pkey PRIMARY KEY (id);

alter table only public.wash_applications add constraint applications_approved_business CHECK (((status <> 'approved'::public.application_status) OR (business_id IS NOT NULL)));

alter table only public.wash_applications add constraint applications_review CHECK (((status = 'pending'::public.application_status) OR (reviewed_at IS NOT NULL)));

alter table only public.wash_applications add constraint wash_applications_capacity_check CHECK (((capacity >= 1) AND (capacity <= 30)));

alter table only public.wash_applications add constraint wash_applications_phone_check CHECK ((phone ~ '^\+[1-9][0-9]{7,14}$'::text));

alter table only public.wash_applications add constraint wash_applications_services_check CHECK ((jsonb_typeof(services) = 'array'::text));

alter table only public.wash_applications add constraint wash_applications_working_hours_check CHECK ((jsonb_typeof(working_hours) = 'array'::text));

alter table only public.wash_applications add constraint wash_applications_pkey PRIMARY KEY (id);

-- ==== Indexes (81) ====

CREATE INDEX admin_notification_reads_admin_idx ON public.admin_notification_reads USING btree (admin_id);

CREATE INDEX admin_notifications_unread_idx ON public.admin_notifications USING btree (created_at DESC) WHERE (NOT read);

CREATE INDEX idx_areas_country ON public.areas USING btree (country_code);

CREATE INDEX audit_logs_actor_idx ON public.audit_logs USING btree (actor_id, at DESC);

CREATE INDEX audit_logs_at_idx ON public.audit_logs USING btree (at DESC);

CREATE INDEX audit_logs_branch_idx ON public.audit_logs USING btree (branch_id, at DESC) WHERE (branch_id IS NOT NULL);

CREATE INDEX audit_logs_entity_idx ON public.audit_logs USING btree (entity, entity_id, at DESC);

CREATE INDEX branch_amenities_amenity_id_idx ON public.branch_amenities USING btree (amenity_id);

CREATE INDEX branch_blocked_slots_branch_idx ON public.branch_blocked_slots USING btree (branch_id, starts_at);

CREATE INDEX branch_blocked_slots_created_by_idx ON public.branch_blocked_slots USING btree (created_by);

CREATE INDEX branch_shares_branch_id_idx ON public.branch_shares USING btree (branch_id);

CREATE INDEX branches_area_id_idx ON public.branches USING btree (area_id) WHERE active;

CREATE INDEX branches_business_id_idx ON public.branches USING btree (business_id);

CREATE INDEX businesses_owner_staff_id_idx ON public.businesses USING btree (owner_staff_id);

CREATE INDEX complaint_notes_author_admin_id_idx ON public.complaint_notes USING btree (author_admin_id);

CREATE INDEX complaint_notes_complaint_idx ON public.complaint_notes USING btree (complaint_id, created_at);

CREATE INDEX complaints_assigned_admin_id_idx ON public.complaints USING btree (assigned_admin_id);

CREATE INDEX complaints_branch_id_idx ON public.complaints USING btree (branch_id);

CREATE INDEX complaints_business_idx ON public.complaints USING btree (business_id);

CREATE INDEX complaints_customer_id_idx ON public.complaints USING btree (customer_id);

CREATE INDEX complaints_order_id_idx ON public.complaints USING btree (order_id);

CREATE INDEX complaints_status_idx ON public.complaints USING btree (status, created_at DESC);

CREATE INDEX customer_favorites_branch_idx ON public.customer_favorites USING btree (branch_id);

CREATE INDEX customer_notifications_inbox_idx ON public.customer_notifications USING btree (customer_id, created_at DESC);

CREATE INDEX customer_notifications_order_id_idx ON public.customer_notifications USING btree (order_id);

CREATE INDEX customer_notifications_unread_idx ON public.customer_notifications USING btree (customer_id) WHERE (NOT read);

CREATE INDEX idx_customers_phone_digits ON public.customers USING btree (regexp_replace(phone, '\D'::text, ''::text, 'g'::text));

CREATE INDEX day_closings_closed_by_idx ON public.day_closings USING btree (closed_by);

CREATE INDEX live_booking_devices_user_id_idx ON public.live_booking_devices USING btree (user_id);

CREATE INDEX offer_branches_branch_idx ON public.offer_branches USING btree (branch_id);

CREATE INDEX offer_categories_category_id_idx ON public.offer_categories USING btree (category_id);

CREATE INDEX offers_business_idx ON public.offers USING btree (business_id) WHERE (business_id IS NOT NULL);

CREATE INDEX offers_live_idx ON public.offers USING btree (starts_at, ends_at) WHERE (status = ANY (ARRAY['scheduled'::public.offer_status, 'active'::public.offer_status]));

CREATE INDEX order_events_order_idx ON public.order_events USING btree (order_id, at);

CREATE INDEX order_items_order_idx ON public.order_items USING btree (order_id, "position");

CREATE INDEX order_items_service_idx ON public.order_items USING btree (service_id);

CREATE INDEX order_notes_author_staff_id_idx ON public.order_notes USING btree (author_staff_id);

CREATE INDEX order_notes_order_idx ON public.order_notes USING btree (order_id, created_at);

CREATE INDEX orders_assigned_staff_id_idx ON public.orders USING btree (assigned_staff_id);

CREATE INDEX orders_branch_schedule_idx ON public.orders USING btree (branch_id, scheduled_at DESC);

CREATE INDEX orders_business_status_idx ON public.orders USING btree (business_id, status);

CREATE INDEX orders_closed_in_day_id_idx ON public.orders USING btree (closed_in_day_id);

CREATE INDEX orders_code_idx ON public.orders USING btree (code);

CREATE INDEX orders_customer_idx ON public.orders USING btree (customer_id, scheduled_at DESC) WHERE (customer_id IS NOT NULL);

CREATE INDEX orders_offer_idx ON public.orders USING btree (offer_id) WHERE (offer_id IS NOT NULL);

CREATE INDEX orders_open_idx ON public.orders USING btree (branch_id, status) WHERE (status = ANY (ARRAY['pending'::public.order_status, 'confirmed'::public.order_status, 'waiting'::public.order_status, 'in_service'::public.order_status]));

CREATE INDEX orders_plate_idx ON public.orders USING btree (plate_normalized);

CREATE INDEX orders_unpaid_idx ON public.orders USING btree (branch_id) WHERE ((status = 'completed'::public.order_status) AND (payment_status = 'pending'::public.order_payment_status));

CREATE INDEX orders_vehicle_id_idx ON public.orders USING btree (vehicle_id);

CREATE INDEX payments_collected_idx ON public.payments USING btree (collected_by, collected_at);

CREATE INDEX payments_order_idx ON public.payments USING btree (order_id);

CREATE INDEX platform_settings_updated_by_idx ON public.platform_settings USING btree (updated_by);

CREATE INDEX push_devices_user_idx ON public.push_devices USING btree (user_id);

CREATE INDEX reviews_branch_idx ON public.reviews USING btree (branch_id, created_at DESC);

CREATE INDEX reviews_business_idx ON public.reviews USING btree (business_id, status);

CREATE INDEX reviews_customer_id_idx ON public.reviews USING btree (customer_id);

CREATE INDEX reviews_reported_idx ON public.reviews USING btree (created_at DESC) WHERE reported_by_wash;

CREATE INDEX reviews_service_id_idx ON public.reviews USING btree (service_id);

CREATE INDEX services_branch_idx ON public.services USING btree (branch_id, type) WHERE active;

CREATE INDEX services_category_id_idx ON public.services USING btree (category_id);

CREATE INDEX staff_branch_idx ON public.staff USING btree (branch_id) WHERE (status = 'active'::public.account_status);

CREATE INDEX staff_business_idx ON public.staff USING btree (business_id, role);

CREATE INDEX staff_shift_patterns_staff_idx ON public.staff_shift_patterns USING btree (staff_id);

CREATE INDEX staff_shifts_branch_idx ON public.staff_shifts USING btree (branch_id, scheduled_start DESC);

CREATE INDEX staff_shifts_review_idx ON public.staff_shifts USING btree (review_status) WHERE (review_status = ANY (ARRAY['submitted'::public.shift_review_status, 'flagged'::public.shift_review_status]));

CREATE INDEX staff_shifts_reviewed_by_idx ON public.staff_shifts USING btree (reviewed_by);

CREATE INDEX staff_shifts_staff_idx ON public.staff_shifts USING btree (staff_id, scheduled_start DESC);

CREATE INDEX transactions_business_date_idx ON public.transactions USING btree (business_id, date DESC);

CREATE INDEX transactions_flag_idx ON public.transactions USING btree (flag) WHERE (flag IS NOT NULL);

CREATE INDEX transactions_payout_id_idx ON public.transactions USING btree (payout_id);

CREATE UNIQUE INDEX vehicles_customer_plate_unique ON public.vehicles USING btree (customer_id, plate_normalized);

CREATE UNIQUE INDEX vehicles_one_default_idx ON public.vehicles USING btree (customer_id) WHERE is_default;

CREATE INDEX vehicles_plate_idx ON public.vehicles USING btree (plate_normalized);

CREATE INDEX vendor_notification_reads_staff_idx ON public.vendor_notification_reads USING btree (staff_id);

CREATE INDEX vendor_notifications_branch_id_idx ON public.vendor_notifications USING btree (branch_id);

CREATE INDEX vendor_notifications_business_idx ON public.vendor_notifications USING btree (business_id, created_at DESC);

CREATE INDEX vendor_notifications_staff_idx ON public.vendor_notifications USING btree (staff_id, created_at DESC) WHERE (staff_id IS NOT NULL);

CREATE INDEX vendor_notifications_unread_idx ON public.vendor_notifications USING btree (business_id) WHERE (NOT read);

CREATE INDEX wash_applications_area_id_idx ON public.wash_applications USING btree (area_id);

CREATE INDEX wash_applications_business_id_idx ON public.wash_applications USING btree (business_id);

CREATE INDEX wash_applications_status_idx ON public.wash_applications USING btree (status, submitted_at DESC);

-- ==== Views (1) ====

create view public.app_health as
 SELECT 1 AS id,
    'healthy'::text AS status,
    now() AS updated_at;

-- ==== Functions that use table types (3) ====

CREATE OR REPLACE FUNCTION public._assert_slot_bookable(p_branch public.branches, p_start timestamp with time zone, p_duration integer, p_exclude_order text DEFAULT NULL::text)
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
$function$
;

CREATE OR REPLACE FUNCTION public._booking_customer()
 RETURNS public.customers
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.booking_lead_min(p_branch public.branches)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  SELECT CASE WHEN p_branch.auto_confirm THEN p_branch.lead_time_min::int
              ELSE greatest(p_branch.lead_time_min::int, 30) END;
$function$
;

-- ==== Foreign keys (79) ====

alter table only public.admin_notification_reads add constraint admin_notification_reads_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admin_users(id) ON DELETE CASCADE;

alter table only public.admin_notification_reads add constraint admin_notification_reads_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.admin_notifications(id) ON DELETE CASCADE;

alter table only public.admin_users add constraint admin_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table only public.areas add constraint areas_country_code_fkey FOREIGN KEY (country_code) REFERENCES public.countries(code);

alter table only public.audit_logs add constraint audit_logs_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE SET NULL;

alter table only public.branch_amenities add constraint branch_amenities_amenity_id_fkey FOREIGN KEY (amenity_id) REFERENCES public.amenities(id);

alter table only public.branch_amenities add constraint branch_amenities_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.branch_blocked_slots add constraint branch_blocked_slots_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.branch_blocked_slots add constraint branch_blocked_slots_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id) ON DELETE SET NULL;

alter table only public.branch_photos add constraint branch_photos_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.branch_shares add constraint branch_shares_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.branch_working_hours add constraint branch_working_hours_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.branches add constraint branches_area_id_fkey1 FOREIGN KEY (area_id) REFERENCES public.areas(id);

alter table only public.branches add constraint branches_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE RESTRICT;

alter table only public.business_settings add constraint business_settings_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;

alter table only public.businesses add constraint businesses_owner_staff_id_fkey FOREIGN KEY (owner_staff_id) REFERENCES public.staff(id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

alter table only public.complaint_notes add constraint complaint_notes_author_admin_id_fkey FOREIGN KEY (author_admin_id) REFERENCES public.admin_users(id) ON DELETE SET NULL;

alter table only public.complaint_notes add constraint complaint_notes_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(id) ON DELETE CASCADE;

alter table only public.complaints add constraint complaints_assigned_admin_id_fkey FOREIGN KEY (assigned_admin_id) REFERENCES public.admin_users(id) ON DELETE SET NULL;

alter table only public.complaints add constraint complaints_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.complaints add constraint complaints_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;

alter table only public.complaints add constraint complaints_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;

alter table only public.complaints add constraint complaints_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;

alter table only public.customer_favorites add constraint customer_favorites_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.customer_favorites add constraint customer_favorites_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;

alter table only public.customer_notifications add constraint customer_notifications_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;

alter table only public.customer_notifications add constraint customer_notifications_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;

alter table only public.customers add constraint customers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table only public.day_closings add constraint day_closings_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;

alter table only public.day_closings add constraint day_closings_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES public.staff(id) ON DELETE RESTRICT;

alter table only public.live_booking_devices add constraint live_booking_devices_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;

alter table only public.live_booking_devices add constraint live_booking_devices_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table only public.offer_branches add constraint offer_branches_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.offer_branches add constraint offer_branches_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.offers(id) ON DELETE CASCADE;

alter table only public.offer_categories add constraint offer_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.service_categories(id);

alter table only public.offer_categories add constraint offer_categories_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.offers(id) ON DELETE CASCADE;

alter table only public.offers add constraint offers_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;

alter table only public.order_events add constraint order_events_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;

alter table only public.order_items add constraint order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;

alter table only public.order_items add constraint order_items_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE SET NULL;

alter table only public.order_notes add constraint order_notes_author_staff_id_fkey FOREIGN KEY (author_staff_id) REFERENCES public.staff(id) ON DELETE SET NULL;

alter table only public.order_notes add constraint order_notes_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;

alter table only public.orders add constraint orders_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES public.staff(id) ON DELETE SET NULL;

alter table only public.orders add constraint orders_branch_id_fkey1 FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;

alter table only public.orders add constraint orders_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE RESTRICT;

alter table only public.orders add constraint orders_closed_in_day_fkey FOREIGN KEY (closed_in_day_id) REFERENCES public.day_closings(id) ON DELETE SET NULL;

alter table only public.orders add constraint orders_customer_id_fkey1 FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE SET NULL;

alter table only public.orders add constraint orders_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.offers(id) ON DELETE SET NULL;

alter table only public.orders add constraint orders_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE SET NULL;

alter table only public.payments add constraint payments_collected_by_fkey FOREIGN KEY (collected_by) REFERENCES public.staff(id) ON DELETE SET NULL;

alter table only public.payments add constraint payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE RESTRICT;

alter table only public.payouts add constraint payouts_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE RESTRICT;

alter table only public.platform_settings add constraint platform_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.admin_users(id) ON DELETE SET NULL;

alter table only public.push_devices add constraint push_devices_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table only public.reviews add constraint reviews_branch_id_fkey1 FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.reviews add constraint reviews_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;

alter table only public.reviews add constraint reviews_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;

alter table only public.reviews add constraint reviews_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;

alter table only public.reviews add constraint reviews_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE SET NULL;

alter table only public.services add constraint services_branch_id_fkey1 FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.services add constraint services_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.service_categories(id);

alter table only public.staff add constraint staff_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE SET NULL;

alter table only public.staff add constraint staff_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;

alter table only public.staff add constraint staff_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table only public.staff_shift_patterns add constraint staff_shift_patterns_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;

alter table only public.staff_shifts add constraint staff_shifts_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;

alter table only public.staff_shifts add constraint staff_shifts_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.staff(id) ON DELETE SET NULL;

alter table only public.staff_shifts add constraint staff_shifts_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE RESTRICT;

alter table only public.transactions add constraint transactions_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE RESTRICT;

alter table only public.transactions add constraint transactions_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE RESTRICT;

alter table only public.transactions add constraint transactions_payout_id_fkey FOREIGN KEY (payout_id) REFERENCES public.payouts(id) ON DELETE SET NULL;

alter table only public.vehicles add constraint vehicles_customer_id_fkey1 FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;

alter table only public.vendor_notification_reads add constraint vendor_notification_reads_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.vendor_notifications(id) ON DELETE CASCADE;

alter table only public.vendor_notification_reads add constraint vendor_notification_reads_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;

alter table only public.vendor_notifications add constraint vendor_notifications_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

alter table only public.vendor_notifications add constraint vendor_notifications_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;

alter table only public.vendor_notifications add constraint vendor_notifications_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;

alter table only public.wash_applications add constraint wash_applications_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id);

alter table only public.wash_applications add constraint wash_applications_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE SET NULL;

-- ==== Triggers (35) ====

CREATE TRIGGER admin_role_permissions_updated_at BEFORE UPDATE ON public.admin_role_permissions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER admin_users_updated_at BEFORE UPDATE ON public.admin_users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER amenities_updated_at BEFORE UPDATE ON public.amenities FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER areas_updated_at BEFORE UPDATE ON public.areas FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER audit_logs_no_update_delete BEFORE DELETE OR UPDATE ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION public.audit_logs_immutable();

CREATE TRIGGER branches_updated_at BEFORE UPDATE ON public.branches FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER business_settings_updated_at BEFORE UPDATE ON public.business_settings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER businesses_updated_at BEFORE UPDATE ON public.businesses FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER complaints_guard_client_writes BEFORE INSERT ON public.complaints FOR EACH ROW EXECUTE FUNCTION public.guard_customer_complaint();

CREATE TRIGGER complaints_updated_at BEFORE UPDATE ON public.complaints FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_admin_complaint_notification AFTER INSERT ON public.complaints FOR EACH ROW EXECUTE FUNCTION public.admin_inbox_notifications();

CREATE TRIGGER customer_notifications_guard_client_writes BEFORE UPDATE ON public.customer_notifications FOR EACH ROW EXECUTE FUNCTION public.guard_customer_notification();

CREATE TRIGGER trg_customer_notifications_send_push AFTER INSERT ON public.customer_notifications FOR EACH ROW EXECUTE FUNCTION public.notify_customer_notification_push();

CREATE TRIGGER customers_guard_client_writes BEFORE INSERT OR UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.guard_customer_row();

CREATE TRIGGER customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER offers_updated_at BEFORE UPDATE ON public.offers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER orders_status_transition BEFORE UPDATE OF status ON public.orders FOR EACH ROW EXECUTE FUNCTION public.guard_order_status_transition();

CREATE TRIGGER orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_order_ledger AFTER INSERT OR UPDATE OF status, total ON public.orders FOR EACH ROW EXECUTE FUNCTION public.order_ledger();

CREATE TRIGGER trg_order_status_notification AFTER INSERT OR UPDATE OF status ON public.orders FOR EACH ROW EXECUTE FUNCTION public.handle_order_status_notification();

CREATE TRIGGER trg_orders_live_push AFTER UPDATE OF status ON public.orders FOR EACH ROW WHEN ((old.status IS DISTINCT FROM new.status)) EXECUTE FUNCTION public.notify_order_live_push();

CREATE TRIGGER trg_wash_order_notifications AFTER INSERT OR UPDATE OF status, scheduled_at ON public.orders FOR EACH ROW EXECUTE FUNCTION public.wash_order_notifications();

CREATE TRIGGER payouts_updated_at BEFORE UPDATE ON public.payouts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER platform_settings_updated_at BEFORE UPDATE ON public.platform_settings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_push_devices_take_over_token BEFORE INSERT ON public.push_devices FOR EACH ROW EXECUTE FUNCTION public.push_devices_take_over_token();

CREATE TRIGGER reviews_guard_client_writes BEFORE INSERT OR UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.guard_customer_review();

CREATE TRIGGER reviews_refresh_ratings AFTER INSERT OR DELETE OR UPDATE OF stars, status, branch_id, business_id ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.refresh_review_ratings();

CREATE TRIGGER reviews_updated_at BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER service_categories_updated_at BEFORE UPDATE ON public.service_categories FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER services_updated_at BEFORE UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER staff_updated_at BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER staff_shifts_updated_at BEFORE UPDATE ON public.staff_shifts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER transactions_updated_at BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER vehicles_updated_at BEFORE UPDATE ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER wash_applications_updated_at BEFORE UPDATE ON public.wash_applications FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ==== Row level security (45) ====

alter table public.admin_notification_reads enable row level security;

alter table public.admin_notifications enable row level security;

alter table public.admin_role_permissions enable row level security;

alter table public.admin_users enable row level security;

alter table public.amenities enable row level security;

alter table public.areas enable row level security;

alter table public.audit_logs enable row level security;

alter table public.branch_amenities enable row level security;

alter table public.branch_blocked_slots enable row level security;

alter table public.branch_photos enable row level security;

alter table public.branch_shares enable row level security;

alter table public.branch_working_hours enable row level security;

alter table public.branches enable row level security;

alter table public.business_settings enable row level security;

alter table public.businesses enable row level security;

alter table public.complaint_notes enable row level security;

alter table public.complaints enable row level security;

alter table public.countries enable row level security;

alter table public.customer_favorites enable row level security;

alter table public.customer_notifications enable row level security;

alter table public.customers enable row level security;

alter table public.day_closings enable row level security;

alter table public.live_booking_devices enable row level security;

alter table public.offer_branches enable row level security;

alter table public.offer_categories enable row level security;

alter table public.offers enable row level security;

alter table public.order_events enable row level security;

alter table public.order_items enable row level security;

alter table public.order_notes enable row level security;

alter table public.orders enable row level security;

alter table public.payments enable row level security;

alter table public.payouts enable row level security;

alter table public.platform_settings enable row level security;

alter table public.push_devices enable row level security;

alter table public.reviews enable row level security;

alter table public.service_categories enable row level security;

alter table public.services enable row level security;

alter table public.staff enable row level security;

alter table public.staff_shift_patterns enable row level security;

alter table public.staff_shifts enable row level security;

alter table public.transactions enable row level security;

alter table public.vehicles enable row level security;

alter table public.vendor_notification_reads enable row level security;

alter table public.vendor_notifications enable row level security;

alter table public.wash_applications enable row level security;

-- ==== Policies (117) ====

create policy vendor_panel_admin_notifications_insert on public.admin_notifications as permissive for insert to washup_vendor_panel
  with check (true);

create policy vendor_panel_admin_notifications_select on public.admin_notifications as permissive for select to washup_vendor_panel
  using (true);

create policy vendor_panel_admin_users_select on public.admin_users as permissive for select to washup_vendor_panel
  using (true);

create policy "Public read amenities" on public.amenities as permissive for select to anon, authenticated
  using ((active = true));

create policy vendor_panel_amenities_select on public.amenities as permissive for select to washup_vendor_panel
  using (true);

create policy "Public read active areas" on public.areas as permissive for select to anon, authenticated
  using ((active = true));

create policy vendor_panel_areas_insert on public.areas as permissive for insert to washup_vendor_panel
  with check (((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NULL) AND (active = false)));

create policy vendor_panel_areas_select on public.areas as permissive for select to washup_vendor_panel
  using (true);

create policy vendor_panel_audit_logs_insert on public.audit_logs as permissive for insert to washup_vendor_panel
  with check (((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL) AND ((actor_type)::text = 'staff'::text) AND (actor_id = ( SELECT public.vendor_panel_staff_id() AS vendor_panel_staff_id))));

create policy vendor_panel_audit_logs_select on public.audit_logs as permissive for select to washup_vendor_panel
  using (((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])) OR (entity_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) OR (EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = audit_logs.entity_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))) OR (((actor_type)::text = 'staff'::text) AND (EXISTS ( SELECT 1
   FROM public.staff s
  WHERE ((s.id = audit_logs.actor_id) AND (s.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))))));

create policy "Public read branch amenities" on public.branch_amenities as permissive for select to anon, authenticated
  using (true);

create policy vendor_panel_branch_amenities_delete on public.branch_amenities as permissive for delete to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_branch_amenities_insert on public.branch_amenities as permissive for insert to washup_vendor_panel
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_branch_amenities_select on public.branch_amenities as permissive for select to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_branch_blocked_slots_delete on public.branch_blocked_slots as permissive for delete to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_branch_blocked_slots_insert on public.branch_blocked_slots as permissive for insert to washup_vendor_panel
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_branch_blocked_slots_select on public.branch_blocked_slots as permissive for select to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy "Public read branch photos" on public.branch_photos as permissive for select to anon, authenticated
  using (true);

create policy "Customers record a share as themselves" on public.branch_shares as permissive for insert to authenticated
  with check (((user_id IS NULL) OR (user_id = ANY (ARRAY[(auth.uid())::text, ( SELECT public.current_active_customer_id() AS current_customer_id)]))));

create policy "Guests record a share without a user" on public.branch_shares as permissive for insert to anon
  with check ((user_id IS NULL));

create policy "Public read branch working hours" on public.branch_working_hours as permissive for select to anon, authenticated
  using (true);

create policy vendor_panel_branch_working_hours_delete on public.branch_working_hours as permissive for delete to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_branch_working_hours_insert on public.branch_working_hours as permissive for insert to washup_vendor_panel
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_branch_working_hours_select on public.branch_working_hours as permissive for select to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy "Public read active branches" on public.branches as permissive for select to anon, authenticated
  using ((active AND public.is_business_live(business_id)));

create policy vendor_panel_branches_select on public.branches as permissive for select to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_branches_update on public.branches as permissive for update to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_business_settings_insert on public.business_settings as permissive for insert to washup_vendor_panel
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_business_settings_select on public.business_settings as permissive for select to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_business_settings_update on public.business_settings as permissive for update to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_businesses_select on public.businesses as permissive for select to washup_vendor_panel
  using ((id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_businesses_update on public.businesses as permissive for update to washup_vendor_panel
  using ((id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check ((id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy "Customers can insert own complaints" on public.complaints as permissive for insert to authenticated
  with check ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Customers can select own complaints" on public.complaints as permissive for select to authenticated
  using ((customer_id = ( SELECT public.current_customer_id() AS current_customer_id)));

create policy "Anyone can read countries" on public.countries as permissive for select to anon, authenticated
  using (true);

create policy vendor_panel_countries_select on public.countries as permissive for select to washup_vendor_panel
  using (true);

create policy "Customers can delete own favorites" on public.customer_favorites as permissive for delete to authenticated
  using ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Customers can insert own favorites" on public.customer_favorites as permissive for insert to authenticated
  with check ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Customers can select own favorites" on public.customer_favorites as permissive for select to authenticated
  using ((customer_id = ( SELECT public.current_customer_id() AS current_customer_id)));

create policy "Customers can mark own notifications read" on public.customer_notifications as permissive for update to authenticated
  using ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)))
  with check ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Customers can select own notifications" on public.customer_notifications as permissive for select to authenticated
  using ((customer_id = ( SELECT public.current_customer_id() AS current_customer_id)));

create policy "Customers can insert own row" on public.customers as permissive for insert to authenticated
  with check ((user_id = ( SELECT auth.uid() AS uid)));

create policy "Customers can select own row" on public.customers as permissive for select to authenticated
  using ((user_id = ( SELECT auth.uid() AS uid)));

create policy "Customers can update own row" on public.customers as permissive for update to authenticated
  using ((user_id = ( SELECT auth.uid() AS uid)))
  with check ((user_id = ( SELECT auth.uid() AS uid)));

create policy vendor_panel_customers_insert on public.customers as permissive for insert to washup_vendor_panel
  with check ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL));

create policy vendor_panel_customers_select on public.customers as permissive for select to washup_vendor_panel
  using ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL));

create policy vendor_panel_customers_update on public.customers as permissive for update to washup_vendor_panel
  using ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL))
  with check ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL));

create policy vendor_panel_day_closings_insert on public.day_closings as permissive for insert to washup_vendor_panel
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_day_closings_select on public.day_closings as permissive for select to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy "Customers manage own live booking devices" on public.live_booking_devices as permissive for all to authenticated
  using ((user_id = ( SELECT auth.uid() AS uid)))
  with check (((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = live_booking_devices.order_id) AND (o.customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)))))));

create policy "Public read offer branches" on public.offer_branches as permissive for select to anon, authenticated
  using (true);

create policy vendor_panel_offer_branches_delete on public.offer_branches as permissive for delete to washup_vendor_panel
  using (public.vendor_panel_owns_offer(offer_id));

create policy vendor_panel_offer_branches_insert on public.offer_branches as permissive for insert to washup_vendor_panel
  with check (((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])) AND public.vendor_panel_owns_offer(offer_id)));

create policy vendor_panel_offer_branches_select on public.offer_branches as permissive for select to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy "Public read offer categories" on public.offer_categories as permissive for select to anon, authenticated
  using (true);

create policy vendor_panel_offer_categories_delete on public.offer_categories as permissive for delete to washup_vendor_panel
  using (public.vendor_panel_owns_offer(offer_id));

create policy vendor_panel_offer_categories_insert on public.offer_categories as permissive for insert to washup_vendor_panel
  with check (public.vendor_panel_owns_offer(offer_id));

create policy vendor_panel_offer_categories_select on public.offer_categories as permissive for select to washup_vendor_panel
  using ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL));

create policy "Public read active offers" on public.offers as permissive for select to anon, authenticated
  using (((status = 'active'::public.offer_status) AND ((business_id IS NULL) OR public.is_business_live(business_id))));

create policy vendor_panel_offers_insert on public.offers as permissive for insert to washup_vendor_panel
  with check (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) AND ((scope)::text = 'wash'::text)));

create policy vendor_panel_offers_select on public.offers as permissive for select to washup_vendor_panel
  using (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) OR (((scope)::text = 'platform'::text) AND (EXISTS ( SELECT 1
   FROM public.offer_branches ob
  WHERE ((ob.offer_id = offers.id) AND (ob.branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[]))))))));

create policy vendor_panel_offers_update on public.offers as permissive for update to washup_vendor_panel
  using (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) AND ((scope)::text = 'wash'::text)))
  with check (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) AND ((scope)::text = 'wash'::text)));

create policy "Customers can select own order events" on public.order_events as permissive for select to authenticated
  using ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.customer_id = ( SELECT public.current_customer_id() AS current_customer_id)))));

create policy vendor_panel_order_events_insert on public.order_events as permissive for insert to washup_vendor_panel
  with check ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_events.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_order_events_select on public.order_events as permissive for select to washup_vendor_panel
  using ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_events.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy "Customers can select own order items" on public.order_items as permissive for select to authenticated
  using ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.customer_id = ( SELECT public.current_customer_id() AS current_customer_id)))));

create policy vendor_panel_order_items_insert on public.order_items as permissive for insert to washup_vendor_panel
  with check ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_items.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_order_items_select on public.order_items as permissive for select to washup_vendor_panel
  using ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_items.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_order_notes_insert on public.order_notes as permissive for insert to washup_vendor_panel
  with check ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_notes.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_order_notes_select on public.order_notes as permissive for select to washup_vendor_panel
  using ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_notes.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy "Customers can select own orders" on public.orders as permissive for select to authenticated
  using ((customer_id = ( SELECT public.current_customer_id() AS current_customer_id)));

create policy vendor_panel_orders_insert on public.orders as permissive for insert to washup_vendor_panel
  with check (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) AND (branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[]))));

create policy vendor_panel_orders_select on public.orders as permissive for select to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_orders_update on public.orders as permissive for update to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) AND (branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[]))));

create policy vendor_panel_payments_insert on public.payments as permissive for insert to washup_vendor_panel
  with check ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = payments.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_payments_select on public.payments as permissive for select to washup_vendor_panel
  using ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = payments.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_payments_update on public.payments as permissive for update to washup_vendor_panel
  using ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = payments.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))))
  with check ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = payments.order_id) AND (o.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_payouts_select on public.payouts as permissive for select to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_platform_settings_select on public.platform_settings as permissive for select to washup_vendor_panel
  using (true);

create policy "Users can manage own push devices" on public.push_devices as permissive for all to authenticated
  using ((user_id = ( SELECT auth.uid() AS uid)))
  with check ((user_id = ( SELECT auth.uid() AS uid)));

create policy vendor_panel_push_devices_all on public.push_devices as permissive for all to washup_vendor_panel
  using (((user_id)::text = ( SELECT public.vendor_panel_user_id() AS vendor_panel_user_id)))
  with check (((user_id)::text = ( SELECT public.vendor_panel_user_id() AS vendor_panel_user_id)));

create policy "Customers can insert review" on public.reviews as permissive for insert to authenticated
  with check ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Customers can update own review" on public.reviews as permissive for update to authenticated
  using ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)))
  with check ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Public read visible reviews" on public.reviews as permissive for select to anon, authenticated
  using ((status = 'visible'::public.review_status));

create policy vendor_panel_reviews_select on public.reviews as permissive for select to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_reviews_update on public.reviews as permissive for update to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy "Public read active categories" on public.service_categories as permissive for select to anon, authenticated
  using ((active = true));

create policy vendor_panel_service_categories_select on public.service_categories as permissive for select to washup_vendor_panel
  using (true);

create policy "Public read active services" on public.services as permissive for select to anon, authenticated
  using ((active = true));

create policy vendor_panel_services_insert on public.services as permissive for insert to washup_vendor_panel
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_services_select on public.services as permissive for select to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_services_update on public.services as permissive for update to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])))
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_staff_insert on public.staff as permissive for insert to washup_vendor_panel
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_staff_select on public.staff as permissive for select to washup_vendor_panel
  using (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) OR ((user_id)::text = ( SELECT public.vendor_panel_user_id() AS vendor_panel_user_id)) OR (id = ( SELECT public.vendor_panel_staff_id() AS vendor_panel_staff_id))));

create policy vendor_panel_staff_update on public.staff as permissive for update to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_staff_shift_patterns_delete on public.staff_shift_patterns as permissive for delete to washup_vendor_panel
  using ((EXISTS ( SELECT 1
   FROM public.staff s
  WHERE ((s.id = staff_shift_patterns.staff_id) AND (s.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_staff_shift_patterns_insert on public.staff_shift_patterns as permissive for insert to washup_vendor_panel
  with check ((EXISTS ( SELECT 1
   FROM public.staff s
  WHERE ((s.id = staff_shift_patterns.staff_id) AND (s.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_staff_shift_patterns_select on public.staff_shift_patterns as permissive for select to washup_vendor_panel
  using ((EXISTS ( SELECT 1
   FROM public.staff s
  WHERE ((s.id = staff_shift_patterns.staff_id) AND (s.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id))))));

create policy vendor_panel_staff_shifts_insert on public.staff_shifts as permissive for insert to washup_vendor_panel
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_staff_shifts_select on public.staff_shifts as permissive for select to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_staff_shifts_update on public.staff_shifts as permissive for update to washup_vendor_panel
  using ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])))
  with check ((branch_id = ANY (( SELECT public.vendor_panel_business_branches() AS vendor_panel_business_branches)::text[])));

create policy vendor_panel_transactions_delete on public.transactions as permissive for delete to washup_vendor_panel
  using (((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)) AND ((status)::text = 'pending'::text)));

create policy vendor_panel_transactions_select on public.transactions as permissive for select to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_transactions_update on public.transactions as permissive for update to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy "Customers can delete own vehicles" on public.vehicles as permissive for delete to authenticated
  using ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Customers can insert own vehicles" on public.vehicles as permissive for insert to authenticated
  with check ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy "Customers can select own vehicles" on public.vehicles as permissive for select to authenticated
  using ((customer_id = ( SELECT public.current_customer_id() AS current_customer_id)));

create policy "Customers can update own vehicles" on public.vehicles as permissive for update to authenticated
  using ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)))
  with check ((customer_id = ( SELECT public.current_active_customer_id() AS current_customer_id)));

create policy vendor_panel_vehicles_insert on public.vehicles as permissive for insert to washup_vendor_panel
  with check ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL));

create policy vendor_panel_vehicles_select on public.vehicles as permissive for select to washup_vendor_panel
  using ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NOT NULL));

create policy vendor_panel_vendor_notification_reads_insert on public.vendor_notification_reads as permissive for insert to washup_vendor_panel
  with check (((staff_id = ( SELECT public.vendor_panel_staff_id() AS vendor_panel_staff_id)) AND (EXISTS ( SELECT 1
   FROM public.vendor_notifications vn
  WHERE ((vn.id = vendor_notification_reads.notification_id) AND (vn.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))))));

create policy vendor_panel_vendor_notification_reads_select on public.vendor_notification_reads as permissive for select to washup_vendor_panel
  using (((staff_id = ( SELECT public.vendor_panel_staff_id() AS vendor_panel_staff_id)) AND (EXISTS ( SELECT 1
   FROM public.vendor_notifications vn
  WHERE ((vn.id = vendor_notification_reads.notification_id) AND (vn.business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))))));

create policy vendor_panel_vendor_notifications_insert on public.vendor_notifications as permissive for insert to washup_vendor_panel
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_vendor_notifications_select on public.vendor_notifications as permissive for select to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_vendor_notifications_update on public.vendor_notifications as permissive for update to washup_vendor_panel
  using ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)))
  with check ((business_id = ( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id)));

create policy vendor_panel_wash_applications_insert on public.wash_applications as permissive for insert to washup_vendor_panel
  with check (((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NULL) AND ((status)::text = 'pending'::text)));

create policy vendor_panel_wash_applications_select on public.wash_applications as permissive for select to washup_vendor_panel
  using ((( SELECT public.vendor_panel_business_id() AS vendor_panel_business_id) IS NULL));

-- ==== Comments on tables (3) ====

comment on table public.areas is 'Cairo districts a branch can belong to.';

comment on table public.audit_logs is 'Append-only. Rows cannot be updated or deleted (trigger). TRUNCATE is reserved for resetting demo environments.';

comment on table public.platform_settings is 'Super Admin settings sections; every change is also written to audit_logs with a reason.';

-- ==== Comments on columns (1) ====

comment on column public.staff.pin_hash is 'bcrypt hash of the 4–6 digit manager PIN (extensions.crypt(pin, extensions.gen_salt(''bf''))). Only owners/managers have one.';

-- ==== Schema privileges (1) ====

grant usage on schema public to washup_vendor_panel;

-- ==== Table / sequence privileges: reset (50) ====

revoke all on table public.admin_notification_reads from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.admin_notifications from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.admin_role_permissions from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.admin_users from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.amenities from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.app_health from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.areas from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.audit_logs from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.branch_amenities from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.branch_blocked_slots from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.branch_photos from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.branch_shares from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.branch_working_hours from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.branches from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.business_settings from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.businesses from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.complaint_notes from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on sequence public.complaint_ticket_seq from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.complaints from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.countries from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.customer_favorites from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.customer_notifications from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.customers from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.day_closings from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.live_booking_devices from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.offer_branches from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.offer_categories from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.offers from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.order_events from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.order_items from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.order_notes from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on sequence public.order_number_app_seq from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on sequence public.order_number_phone_seq from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on sequence public.order_number_walk_in_seq from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.orders from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.payments from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.payouts from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.platform_settings from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.push_devices from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.reviews from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.service_categories from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.services from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.staff from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.staff_shift_patterns from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.staff_shifts from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.transactions from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.vehicles from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.vendor_notification_reads from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.vendor_notifications from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on table public.wash_applications from public, anon, authenticated, service_role, washup_vendor_panel;

-- ==== Table / sequence privileges (131) ====

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.admin_notification_reads to service_role;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.admin_notifications to service_role;

grant insert on table public.admin_notifications to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.admin_role_permissions to service_role;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.admin_users to service_role;

grant select on table public.amenities to anon;

grant select on table public.amenities to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.amenities to service_role;

grant select on table public.amenities to washup_vendor_panel;

grant select on table public.app_health to anon;

grant select on table public.app_health to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.app_health to service_role;

grant select on table public.areas to anon;

grant select on table public.areas to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.areas to service_role;

grant insert, select on table public.areas to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.audit_logs to service_role;

grant insert, select on table public.audit_logs to washup_vendor_panel;

grant select on table public.branch_amenities to anon;

grant select on table public.branch_amenities to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.branch_amenities to service_role;

grant delete, insert, select on table public.branch_amenities to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.branch_blocked_slots to service_role;

grant delete, insert, select on table public.branch_blocked_slots to washup_vendor_panel;

grant select on table public.branch_photos to anon;

grant select on table public.branch_photos to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.branch_photos to service_role;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.branch_shares to service_role;

grant select on table public.branch_working_hours to anon;

grant select on table public.branch_working_hours to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.branch_working_hours to service_role;

grant delete, insert, select on table public.branch_working_hours to washup_vendor_panel;

grant select on table public.branches to anon;

grant select on table public.branches to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.branches to service_role;

grant select on table public.branches to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.business_settings to service_role;

grant insert, select, update on table public.business_settings to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.businesses to service_role;

grant select on table public.businesses to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.complaint_notes to service_role;

grant usage on sequence public.complaint_ticket_seq to authenticated;

grant select, update, usage on sequence public.complaint_ticket_seq to service_role;

grant usage on sequence public.complaint_ticket_seq to washup_vendor_panel;

grant insert, select on table public.complaints to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.complaints to service_role;

grant select on table public.countries to anon;

grant select on table public.countries to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.countries to service_role;

grant select on table public.countries to washup_vendor_panel;

grant delete, insert, select on table public.customer_favorites to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.customer_favorites to service_role;

grant select, update on table public.customer_notifications to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.customer_notifications to service_role;

grant insert, select, update on table public.customers to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.customers to service_role;

grant insert, select on table public.customers to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.day_closings to service_role;

grant insert, select on table public.day_closings to washup_vendor_panel;

grant delete, insert, select, update on table public.live_booking_devices to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.live_booking_devices to service_role;

grant select on table public.offer_branches to anon;

grant select on table public.offer_branches to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.offer_branches to service_role;

grant delete, insert, select on table public.offer_branches to washup_vendor_panel;

grant select on table public.offer_categories to anon;

grant select on table public.offer_categories to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.offer_categories to service_role;

grant delete, insert, select on table public.offer_categories to washup_vendor_panel;

grant select on table public.offers to anon;

grant select on table public.offers to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.offers to service_role;

grant insert, select, update on table public.offers to washup_vendor_panel;

grant select on table public.order_events to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.order_events to service_role;

grant insert, select on table public.order_events to washup_vendor_panel;

grant select on table public.order_items to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.order_items to service_role;

grant insert, select on table public.order_items to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.order_notes to service_role;

grant insert, select on table public.order_notes to washup_vendor_panel;

grant usage on sequence public.order_number_app_seq to authenticated;

grant select, update, usage on sequence public.order_number_app_seq to service_role;

grant usage on sequence public.order_number_app_seq to washup_vendor_panel;

grant usage on sequence public.order_number_phone_seq to authenticated;

grant select, update, usage on sequence public.order_number_phone_seq to service_role;

grant usage on sequence public.order_number_phone_seq to washup_vendor_panel;

grant usage on sequence public.order_number_walk_in_seq to authenticated;

grant select, update, usage on sequence public.order_number_walk_in_seq to service_role;

grant usage on sequence public.order_number_walk_in_seq to washup_vendor_panel;

grant select on table public.orders to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.orders to service_role;

grant insert, select, update on table public.orders to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.payments to service_role;

grant insert, select on table public.payments to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.payouts to service_role;

grant select on table public.payouts to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.platform_settings to service_role;

grant select on table public.platform_settings to washup_vendor_panel;

grant delete, insert, select, update on table public.push_devices to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.push_devices to service_role;

grant delete, insert, select, update on table public.push_devices to washup_vendor_panel;

grant select on table public.reviews to anon;

grant insert, select, update on table public.reviews to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.reviews to service_role;

grant select on table public.reviews to washup_vendor_panel;

grant select on table public.service_categories to anon;

grant select on table public.service_categories to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.service_categories to service_role;

grant select on table public.service_categories to washup_vendor_panel;

grant select on table public.services to anon;

grant select on table public.services to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.services to service_role;

grant insert, select, update on table public.services to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.staff to service_role;

grant insert, select on table public.staff to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.staff_shift_patterns to service_role;

grant delete, insert, select on table public.staff_shift_patterns to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.staff_shifts to service_role;

grant insert, select, update on table public.staff_shifts to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.transactions to service_role;

grant delete, select on table public.transactions to washup_vendor_panel;

grant delete, insert, select, update on table public.vehicles to authenticated;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.vehicles to service_role;

grant insert, select on table public.vehicles to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.vendor_notification_reads to service_role;

grant insert, select on table public.vendor_notification_reads to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.vendor_notifications to service_role;

grant insert, select on table public.vendor_notifications to washup_vendor_panel;

grant delete, insert, maintain, references, select, trigger, truncate, update on table public.wash_applications to service_role;

grant insert, select on table public.wash_applications to washup_vendor_panel;

-- ==== Column privileges (13) ====

grant select (id) on table public.admin_notifications to washup_vendor_panel;

grant select (id, name) on table public.admin_users to washup_vendor_panel;

grant insert (branch_id, user_id, platform) on table public.branch_shares to anon;

grant insert (branch_id, user_id, platform) on table public.branch_shares to authenticated;

grant update (name, address, lat, lng, phone, capacity, active, auto_confirm, slot_interval_min, lead_time_min, max_advance_days, free_cancel_min, no_show_grace_min, reminder_min) on table public.branches to washup_vendor_panel;

grant update (name) on table public.businesses to washup_vendor_panel;

grant update (locale, notify_reminders, notify_offers) on table public.customers to authenticated;

grant update (last_active_at) on table public.customers to washup_vendor_panel;

grant update (status) on table public.payments to washup_vendor_panel;

grant update (reply, reply_at, reported_by_wash, report_reason) on table public.reviews to washup_vendor_panel;

grant update (user_id, branch_id, name, role, status, max_discount_pct, permissions) on table public.staff to washup_vendor_panel;

grant update (status) on table public.transactions to washup_vendor_panel;

grant update (read) on table public.vendor_notifications to washup_vendor_panel;

-- ==== Function privileges: reset (61) ====

revoke all on function public._assert_customer_can_book(text,text,timestamp with time zone,integer,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public._assert_slot_bookable(public.branches,timestamp with time zone,integer,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public._booking_customer() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public._order_json(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.add_customer_order_note(text,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.admin_inbox_notifications() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.app_order_ledger() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.audit_logs_immutable() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.booking_lead_min(public.branches) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.branch_money(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.branch_timezone(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.cancel_order(text,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.clean_demo_auth_users() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.close_stale_orders() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.create_order(text,text,text,timestamp with time zone,text[]) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.current_active_customer_id() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.current_customer_id() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.delete_my_account() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.discover_branches(double precision,double precision,text,text,double precision,integer,integer,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.format_booking_time(timestamp with time zone,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.format_booking_time(timestamp with time zone,text,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.gen_check_in_code() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.gen_id(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.generate_settlements(date,date) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.get_branch_slots(text,date,integer,text,boolean) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.get_support_info() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.guard_customer_complaint() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.guard_customer_notification() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.guard_customer_review() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.guard_customer_row() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.guard_order_status_transition() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.handle_order_status_notification() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.is_business_live(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.is_localized(jsonb) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.is_staff_or_admin() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.next_complaint_ticket() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.next_order_number(public.order_source) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.normalize_plate(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.notify_admins(public.admin_notification_type,jsonb,jsonb,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.notify_customer_notification_push() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.notify_order_live_push() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.notify_wash(text,text,public.vendor_notification_type,text,text,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.order_ledger() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.panel_push(text,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.push_devices_take_over_token() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.quote_order(text,text,text[]) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.refresh_offer_statuses() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.refresh_review_ratings() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.reschedule_order(text,timestamp with time zone) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.rls_auto_enable() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.send_push_config() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.set_updated_at() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.sync_customer_profile(text,text,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.vendor_panel_app_phone_confirmed(text,text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.vendor_panel_business_branches() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.vendor_panel_business_id() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.vendor_panel_owns_offer(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.vendor_panel_staff_id() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.vendor_panel_staff_phone_taken(text) from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.vendor_panel_user_id() from public, anon, authenticated, service_role, washup_vendor_panel;

revoke all on function public.wash_order_notifications() from public, anon, authenticated, service_role, washup_vendor_panel;

-- ==== Function privileges (107) ====

grant execute on function public._assert_customer_can_book(text,text,timestamp with time zone,integer,text) to service_role;

grant execute on function public._assert_slot_bookable(public.branches,timestamp with time zone,integer,text) to service_role;

grant execute on function public._booking_customer() to service_role;

grant execute on function public._order_json(text) to service_role;

grant execute on function public.add_customer_order_note(text,text) to authenticated;

grant execute on function public.add_customer_order_note(text,text) to service_role;

grant execute on function public.admin_inbox_notifications() to service_role;

grant execute on function public.app_order_ledger() to service_role;

grant execute on function public.audit_logs_immutable() to service_role;

grant execute on function public.booking_lead_min(public.branches) to public;

grant execute on function public.booking_lead_min(public.branches) to service_role;

grant execute on function public.branch_money(text) to service_role;

grant execute on function public.branch_timezone(text) to public;

grant execute on function public.branch_timezone(text) to anon;

grant execute on function public.branch_timezone(text) to authenticated;

grant execute on function public.branch_timezone(text) to service_role;

grant execute on function public.branch_timezone(text) to washup_vendor_panel;

grant execute on function public.cancel_order(text,text) to authenticated;

grant execute on function public.cancel_order(text,text) to service_role;

grant execute on function public.clean_demo_auth_users() to service_role;

grant execute on function public.close_stale_orders() to service_role;

grant execute on function public.create_order(text,text,text,timestamp with time zone,text[]) to authenticated;

grant execute on function public.create_order(text,text,text,timestamp with time zone,text[]) to service_role;

grant execute on function public.current_active_customer_id() to authenticated;

grant execute on function public.current_active_customer_id() to service_role;

grant execute on function public.current_customer_id() to authenticated;

grant execute on function public.current_customer_id() to service_role;

grant execute on function public.delete_my_account() to authenticated;

grant execute on function public.delete_my_account() to service_role;

grant execute on function public.discover_branches(double precision,double precision,text,text,double precision,integer,integer,text) to public;

grant execute on function public.discover_branches(double precision,double precision,text,text,double precision,integer,integer,text) to anon;

grant execute on function public.discover_branches(double precision,double precision,text,text,double precision,integer,integer,text) to authenticated;

grant execute on function public.discover_branches(double precision,double precision,text,text,double precision,integer,integer,text) to service_role;

grant execute on function public.format_booking_time(timestamp with time zone,text) to public;

grant execute on function public.format_booking_time(timestamp with time zone,text) to service_role;

grant execute on function public.format_booking_time(timestamp with time zone,text,text) to public;

grant execute on function public.format_booking_time(timestamp with time zone,text,text) to service_role;

grant execute on function public.gen_check_in_code() to service_role;

grant execute on function public.gen_check_in_code() to washup_vendor_panel;

grant execute on function public.gen_id(text) to authenticated;

grant execute on function public.gen_id(text) to service_role;

grant execute on function public.gen_id(text) to washup_vendor_panel;

grant execute on function public.generate_settlements(date,date) to service_role;

grant execute on function public.get_branch_slots(text,date,integer,text,boolean) to public;

grant execute on function public.get_branch_slots(text,date,integer,text,boolean) to anon;

grant execute on function public.get_branch_slots(text,date,integer,text,boolean) to authenticated;

grant execute on function public.get_branch_slots(text,date,integer,text,boolean) to service_role;

grant execute on function public.get_branch_slots(text,date,integer,text,boolean) to washup_vendor_panel;

grant execute on function public.get_support_info() to anon;

grant execute on function public.get_support_info() to authenticated;

grant execute on function public.get_support_info() to service_role;

grant execute on function public.guard_customer_complaint() to service_role;

grant execute on function public.guard_customer_notification() to service_role;

grant execute on function public.guard_customer_review() to service_role;

grant execute on function public.guard_customer_row() to service_role;

grant execute on function public.guard_order_status_transition() to public;

grant execute on function public.guard_order_status_transition() to service_role;

grant execute on function public.handle_order_status_notification() to service_role;

grant execute on function public.is_business_live(text) to anon;

grant execute on function public.is_business_live(text) to authenticated;

grant execute on function public.is_business_live(text) to service_role;

grant execute on function public.is_localized(jsonb) to anon;

grant execute on function public.is_localized(jsonb) to authenticated;

grant execute on function public.is_localized(jsonb) to service_role;

grant execute on function public.is_localized(jsonb) to washup_vendor_panel;

grant execute on function public.is_staff_or_admin() to service_role;

grant execute on function public.next_complaint_ticket() to authenticated;

grant execute on function public.next_complaint_ticket() to service_role;

grant execute on function public.next_order_number(public.order_source) to service_role;

grant execute on function public.next_order_number(public.order_source) to washup_vendor_panel;

grant execute on function public.normalize_plate(text) to anon;

grant execute on function public.normalize_plate(text) to authenticated;

grant execute on function public.normalize_plate(text) to service_role;

grant execute on function public.normalize_plate(text) to washup_vendor_panel;

grant execute on function public.notify_admins(public.admin_notification_type,jsonb,jsonb,text) to service_role;

grant execute on function public.notify_customer_notification_push() to service_role;

grant execute on function public.notify_order_live_push() to service_role;

grant execute on function public.notify_wash(text,text,public.vendor_notification_type,text,text,text) to service_role;

grant execute on function public.order_ledger() to service_role;

grant execute on function public.panel_push(text,text) to service_role;

grant execute on function public.push_devices_take_over_token() to service_role;

grant execute on function public.quote_order(text,text,text[]) to authenticated;

grant execute on function public.quote_order(text,text,text[]) to service_role;

grant execute on function public.refresh_offer_statuses() to service_role;

grant execute on function public.refresh_review_ratings() to service_role;

grant execute on function public.reschedule_order(text,timestamp with time zone) to authenticated;

grant execute on function public.reschedule_order(text,timestamp with time zone) to service_role;

grant execute on function public.rls_auto_enable() to service_role;

grant execute on function public.send_push_config() to service_role;

grant execute on function public.set_updated_at() to service_role;

grant execute on function public.sync_customer_profile(text,text,text) to authenticated;

grant execute on function public.sync_customer_profile(text,text,text) to service_role;

grant execute on function public.vendor_panel_app_phone_confirmed(text,text) to service_role;

grant execute on function public.vendor_panel_app_phone_confirmed(text,text) to washup_vendor_panel;

grant execute on function public.vendor_panel_business_branches() to service_role;

grant execute on function public.vendor_panel_business_branches() to washup_vendor_panel;

grant execute on function public.vendor_panel_business_id() to service_role;

grant execute on function public.vendor_panel_business_id() to washup_vendor_panel;

grant execute on function public.vendor_panel_owns_offer(text) to service_role;

grant execute on function public.vendor_panel_owns_offer(text) to washup_vendor_panel;

grant execute on function public.vendor_panel_staff_id() to service_role;

grant execute on function public.vendor_panel_staff_id() to washup_vendor_panel;

grant execute on function public.vendor_panel_staff_phone_taken(text) to service_role;

grant execute on function public.vendor_panel_staff_phone_taken(text) to washup_vendor_panel;

grant execute on function public.vendor_panel_user_id() to service_role;

grant execute on function public.vendor_panel_user_id() to washup_vendor_panel;

grant execute on function public.wash_order_notifications() to service_role;

-- ==== Realtime publication (2) ====

do $x$ begin if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'customer_notifications') then alter publication supabase_realtime add table public.customer_notifications; end if; end $x$;

do $x$ begin if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'orders') then alter publication supabase_realtime add table public.orders; end if; end $x$;

-- ==== Scheduled jobs (pg_cron) (3) ====

select cron.schedule('close-stale-orders', '*/10 * * * *', 'SELECT public.close_stale_orders()');

select cron.schedule('generate-settlements', '0 3 * * 1', 'select public.generate_settlements(current_date - 7, current_date - 1)');

select cron.schedule('refresh-offer-statuses', '*/5 * * * *', 'select public.refresh_offer_statuses()');

-- ==== Storage buckets (definitions only) (3) ====

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('application-documents', 'application-documents', false, 10485760, '{application/pdf,image/jpeg,image/png}') on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('branch-photos', 'branch-photos', true, 5242880, '{image/jpeg,image/png,image/webp}') on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('legal', 'legal', true, null, NULL) on conflict (id) do nothing;

select pg_catalog.set_config('search_path', '"$user", public, extensions', false);
