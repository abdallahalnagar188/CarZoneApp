-- In-app account deletion (App Store Guideline 5.1.1(v)).
-- Removes the caller's customer profile (cars, favorites, reviews, complaints and
-- notifications cascade) and their auth user (sessions and push devices cascade).
-- Orders stay with the wash for its books, with customer_id/vehicle_id set to null.
-- A booking that is still open blocks deletion so the wash is not left waiting.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
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
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
