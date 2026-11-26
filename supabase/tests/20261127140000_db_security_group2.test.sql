-- Checks for migrations 20261127140000 … 20261127143000 (GAP-060, 061, 062). Runs in one transaction that is
-- always rolled back: the DO block ends with an exception carrying the result, then ROLLBACK. Nothing persists
-- (a deleted test customer and inserted share rows come back with the rollback). Prints no personal data.
-- Before the migrations are applied, run it with their text pasted between BEGIN and the DO block.
-- Expected: "GROUP2 TEST: 9 passed, failures: none".

begin;

do $t$
declare
  pass int := 0;
  fail text := '';
  v_cmd text;
  v_staff uuid;
  v_cust record;
  v_other uuid;
  v_branch text;
  v_recent int;
  n0 int;
  n1 int;
  v_rb text;
  v_visible int;
begin
  -- GAP-060: the weekly settlements job carries its own timeout.
  select command into v_cmd from cron.job where jobname = 'generate-settlements';
  if v_cmd like 'set statement_timeout = ''5min''; select public.generate_settlements(%' then pass := pass + 1;
  else fail := fail || ' | cron command: ' || coalesce(v_cmd, 'missing'); end if;

  -- GAP-061: a staff login is refused and survives.
  select s.user_id into v_staff from public.staff s
  where s.user_id is not null order by exists (select 1 from public.customers c where c.user_id = s.user_id) desc limit 1;
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_staff::text, true);
  execute 'set local role authenticated';
  begin
    perform public.delete_my_account();
    fail := fail || ' | staff login was deleted';
  exception when others then
    if sqlerrm = 'staff_account' then pass := pass + 1; else fail := fail || ' | staff: ' || sqlerrm; end if;
  end;
  execute 'reset role';
  if exists (select 1 from auth.users where id = v_staff) and exists (select 1 from public.staff where user_id = v_staff) then
    pass := pass + 1;
  else fail := fail || ' | staff login or row missing'; end if;

  -- GAP-061: a plain customer without an open booking can still delete the account.
  select c.id, c.user_id into v_cust from public.customers c
  where c.user_id is not null
    and not exists (select 1 from public.staff s where s.user_id = c.user_id)
    and not exists (select 1 from public.admin_users a where a.user_id = c.user_id)
    and not exists (select 1 from public.orders o where o.customer_id = c.id and o.status in ('pending', 'confirmed', 'waiting', 'in_service'))
  limit 1;
  perform set_config('request.jwt.claims', json_build_object('sub', v_cust.user_id, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_cust.user_id::text, true);
  execute 'set local role authenticated';
  begin
    perform public.delete_my_account();
  exception when others then
    fail := fail || ' | customer delete: ' || sqlerrm;
  end;
  execute 'reset role';
  if not exists (select 1 from public.customers where id = v_cust.id) and not exists (select 1 from auth.users where id = v_cust.user_id) then
    pass := pass + 1;
  else fail := fail || ' | customer or auth user still there'; end if;

  -- GAP-062: guest shares are capped at 60 per branch per hour, without an error.
  select id into v_branch from public.branches where active order by id limit 1;
  select count(*) into v_recent from public.branch_shares
  where branch_id = v_branch and user_id is null and created_at > now() - interval '1 hour';
  select count(*) into n0 from public.branch_shares where branch_id = v_branch;
  execute 'set local role anon';
  begin
    for i in 1..61 loop
      insert into public.branch_shares (branch_id, user_id, platform) values (v_branch, null, 'native_share');
    end loop;
  exception when others then
    fail := fail || ' | guest share: ' || sqlerrm;
  end;
  execute 'reset role';
  select count(*) into n1 from public.branch_shares where branch_id = v_branch;
  if n1 - n0 = greatest(60 - v_recent, 0) then pass := pass + 1;
  else fail := fail || format(' | guest shares added %s, expected %s', n1 - n0, greatest(60 - v_recent, 0)); end if;

  -- GAP-062: a signed-in customer is capped at 20 per branch per hour.
  select c.user_id into v_other from public.customers c where c.user_id is not null and c.user_id is distinct from v_cust.user_id limit 1;
  perform set_config('request.jwt.claims', json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_other::text, true);
  select count(*) into v_recent from public.branch_shares
  where branch_id = v_branch and user_id = v_other::text and created_at > now() - interval '1 hour';
  select count(*) into n0 from public.branch_shares where branch_id = v_branch and user_id = v_other::text;
  execute 'set local role authenticated';
  begin
    for i in 1..21 loop
      insert into public.branch_shares (branch_id, user_id, platform) values (v_branch, v_other::text, 'native_share');
    end loop;
  exception when others then
    fail := fail || ' | customer share: ' || sqlerrm;
  end;
  execute 'reset role';
  select count(*) into n1 from public.branch_shares where branch_id = v_branch and user_id = v_other::text;
  if n1 - n0 = greatest(20 - v_recent, 0) then pass := pass + 1;
  else fail := fail || format(' | customer shares added %s, expected %s', n1 - n0, greatest(20 - v_recent, 0)); end if;

  -- GAP-062: platform is at most 32 characters (another branch: v_branch is at its cap, the trigger would drop the row).
  begin
    insert into public.branch_shares (branch_id, user_id, platform)
    values ((select id from public.branches where id <> v_branch order by id limit 1), null, repeat('x', 40));
    fail := fail || ' | 40-character platform accepted';
  exception when check_violation then
    pass := pass + 1;
  end;

  -- GAP-062: guests read a wash's reviews through branch_reviews(), which has no internal columns.
  select branch_id into v_rb from public.reviews where status = 'visible' group by branch_id order by count(*) desc limit 1;
  select count(*) into v_visible from public.reviews where branch_id = v_rb and status = 'visible';
  execute 'set local role anon';
  begin
    select count(*) into n1 from public.branch_reviews(v_rb, 100);
  exception when others then
    fail := fail || ' | branch_reviews as anon: ' || sqlerrm;
  end;
  execute 'reset role';
  if v_rb is not null and n1 = v_visible and n1 > 0 then pass := pass + 1;
  else fail := fail || format(' | branch_reviews returned %s of %s', n1, v_visible); end if;
  if not exists (
    select 1 from pg_proc p, unnest(p.proargnames) a(n)
    where p.oid = 'public.branch_reviews(text,integer,integer)'::regprocedure
      and a.n in ('customer_id', 'order_id', 'reported_by_wash', 'report_reason', 'hidden_reason')
  ) then pass := pass + 1;
  else fail := fail || ' | branch_reviews exposes an internal column'; end if;

  raise exception 'GROUP2 TEST: % passed, failures:%', pass, case when fail = '' then ' none' else fail end;
end $t$;

rollback;
