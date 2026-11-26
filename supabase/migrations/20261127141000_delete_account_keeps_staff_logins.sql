-- GAP-061 (system audit): "Delete my account" must not delete the login of a wash staff member or an admin.
--
-- delete_my_account() deletes the caller's auth.users row. staff.user_id, admin_users.user_id and customers.user_id
-- reference auth.users ON DELETE SET NULL (see the baseline), so a person who uses the customer app with the same
-- phone / e-mail as their staff or admin login would silently lose that login (their staff / admin row survives
-- without a user). The RPC now refuses with "staff_account"; the customer app shows a message asking them to
-- contact support (older app versions show their generic "could not delete" message). Everything else is unchanged.
--
-- The remaining delete behaviour, now declared in the baseline: customers → vehicles, reviews, complaints,
-- favorites, notifications cascade; orders keep their history (customer_id SET NULL); transactions / payments
-- restrict deleting an order.
--
-- Verify (rolled back): call it as a user that has a staff row → error staff_account; as a plain customer without
-- an open booking → customer + auth user gone.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_customer_id text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if exists (select 1 from public.staff where user_id = v_uid)
     or exists (select 1 from public.admin_users where user_id = v_uid) then
    raise exception 'staff_account'
      using hint = 'This login also belongs to a wash staff member or an admin; it is removed by an administrator.';
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
$function$;
