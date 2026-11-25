-- NOT APPLIED — to be reviewed and applied by the lead
--
-- GAP-034: the customer app's booking summary priced orders with its own offer rules, so it
-- could show a discount create_order never applies (platform offers, offers limited to other
-- categories). quote_order returns the price create_order would charge right now, using the
-- same rules as the live create_order (vendor/supabase/migrations/20261025090000, lock keys
-- renamed by 20261101120000): live wash only, active primary + add-ons of this branch, best
-- live offer joined to the branch through offer_branches, matching offer_categories (none =
-- every category), applied to the primary service only, percent rounded with round().
--
-- Read-only (STABLE), takes no lock and writes nothing. Keep its offer block in step with
-- create_order whenever that one changes (better: have create_order call a shared helper).
--
-- The app calls it on the booking summary and falls back to its local estimate while this
-- function does not exist (PostgREST PGRST202), so it is safe to ship the app first.
--
-- Idempotent: CREATE OR REPLACE + explicit grants.

create or replace function public.quote_order(
  p_branch_id text,
  p_primary_service_id text,
  p_addon_service_ids text[] default '{}'::text[]
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_branch public.branches%rowtype;
  v_primary public.services%rowtype;
  v_addons public.services[];
  v_addon_ids text[] := array(select distinct unnest(coalesce(p_addon_service_ids, '{}')));
  v_subtotal numeric;
  v_duration int;
  v_offer_id text;
  v_offer_type public.discount_type;
  v_offer_value numeric;
  v_discount numeric := 0;
begin
  select b.* into v_branch
  from public.branches b
  join public.businesses biz on biz.id = b.business_id
  where b.id = p_branch_id and b.active and biz.status = 'active';
  if not found then
    raise exception 'branch_unavailable';
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

  -- Same block as create_order: best live offer for this branch, primary service only.
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

  return jsonb_build_object(
    'subtotal', v_subtotal,
    'discount', v_discount,
    'total', v_subtotal - v_discount,
    'offer_id', case when v_discount > 0 then v_offer_id end,
    'discount_pct', case when v_discount > 0 and v_offer_type = 'percent' then v_offer_value end,
    'duration_min', v_duration
  );
end;
$function$;

-- Signed-in customers only (the summary comes after sign-in); no anon surface (GAP-024).
revoke all on function public.quote_order(text, text, text[]) from public, anon;
grant execute on function public.quote_order(text, text, text[]) to authenticated;

-- The offer → category links, readable like offer_branches already is, so the app's offer
-- badges (wash page, service picker) follow the same category rule. The app embeds
-- offer_categories in its offers query and drops it again while this is not applied.
grant select on public.offer_categories to anon, authenticated;
drop policy if exists "Public read offer categories" on public.offer_categories;
create policy "Public read offer categories" on public.offer_categories
  for select to anon, authenticated
  using (true);
