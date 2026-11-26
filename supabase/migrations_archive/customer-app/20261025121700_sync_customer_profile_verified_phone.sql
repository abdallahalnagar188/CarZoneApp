-- sync_customer_profile links a customer by phone only when Supabase Auth has
-- verified that phone by SMS code. Google/Apple users type their number without
-- proof, so they can never take over an existing customer through it.
-- A verified number also wins back a profile someone else registered with it
-- without proof, so the real owner is never locked out of their own number.

-- Phone numbers are compared as digits only: customers store '+2010…', auth.users stores '2010…'.
create index if not exists idx_customers_phone_digits
  on public.customers (regexp_replace(phone, '\D', '', 'g'));

create or replace function public.sync_customer_profile(
  p_phone text,
  p_name text default null,
  p_locale text default 'ar'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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
$$;

revoke all on function public.sync_customer_profile(text, text, text) from public, anon;
grant execute on function public.sync_customer_profile(text, text, text) to authenticated;
