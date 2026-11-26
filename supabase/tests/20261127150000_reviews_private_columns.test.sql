-- Checks for the PENDING migration 20261127150000_reviews_private_columns (GAP-062 stage 2). One transaction,
-- always rolled back. Run it with the migration's text pasted between BEGIN and the DO block (and, before
-- 20261127143000 is applied, that one too). Expected: "REVIEWS STAGE 2 TEST: 4 passed, failures: none".

begin;

do $t$
declare
  pass int := 0;
  fail text := '';
  v_cust record;
  v_branch text;
  n int;
  v_own int;
begin
  -- anon can no longer read the table.
  execute 'set local role anon';
  begin
    select count(*) into n from public.reviews;
    fail := fail || ' | anon still reads reviews';
  exception when insufficient_privilege then
    pass := pass + 1;
  end;
  execute 'reset role';

  -- a customer reads exactly their own reviews.
  select c.id, c.user_id into v_cust from public.customers c
  where c.user_id is not null and exists (select 1 from public.reviews r where r.customer_id = c.id) limit 1;
  select count(*) into v_own from public.reviews where customer_id = v_cust.id;
  perform set_config('request.jwt.claims', json_build_object('sub', v_cust.user_id, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_cust.user_id::text, true);
  execute 'set local role authenticated';
  select count(*) into n from public.reviews;
  execute 'reset role';
  if n = v_own and n > 0 then pass := pass + 1; else fail := fail || format(' | customer sees %s, owns %s', n, v_own); end if;

  -- the wash page still works for guests and customers through branch_reviews().
  select branch_id into v_branch from public.reviews where status = 'visible' group by branch_id order by count(*) desc limit 1;
  execute 'set local role anon';
  select count(*) into n from public.branch_reviews(v_branch, 100);
  execute 'reset role';
  if n > 0 then pass := pass + 1; else fail := fail || ' | branch_reviews empty for anon'; end if;
  execute 'set local role authenticated';
  select count(*) into n from public.branch_reviews(v_branch, 100);
  execute 'reset role';
  if n > 0 then pass := pass + 1; else fail := fail || ' | branch_reviews empty for a customer'; end if;

  raise exception 'REVIEWS STAGE 2 TEST: % passed, failures:%', pass, case when fail = '' then ' none' else fail end;
end $t$;

rollback;
