-- GAP-062 (system audit), part 2 — stage 1 of 2: a public read of reviews without the internal columns.
--
-- anon and authenticated can SELECT every column of a visible review today, including customer_id (links one
-- person's reviews across washes), reported_by_wash and report_reason (the wash's complaint to WashUp). The
-- released customer app reads the table with select=* (branch page, "my reviews", order review), so the table
-- grant cannot be narrowed yet without breaking those screens in the store builds.
--
-- Stage 1 (this file, safe for every app version): branch_reviews(branch, limit, offset) returns visible reviews
-- with the public columns only. The customer app reads the branch page through it from the next release.
-- Stage 2 (20261127150000_reviews_private_columns.sql, PENDING): once that release is the minimum supported
-- version, the table is limited to the customer's own reviews and anon loses its SELECT.
--
-- Verify (rolled back): as anon, select * from branch_reviews('<branch>') returns no customer_id / report_reason.

create or replace function public.branch_reviews(p_branch_id text, p_limit integer default 25, p_offset integer default 0)
returns table (
  id text,
  branch_id text,
  business_id text,
  service_id text,
  stars smallint,
  comment jsonb,
  tags text[],
  reply text,
  reply_at timestamp with time zone,
  created_at timestamp with time zone
)
language sql
stable
security definer
set search_path to ''
as $function$
  select r.id, r.branch_id, r.business_id, r.service_id, r.stars, r.comment, r.tags, r.reply, r.reply_at, r.created_at
  from public.reviews r
  where r.branch_id = p_branch_id
    and r.status = 'visible'::public.review_status
  order by r.created_at desc, r.id
  limit least(greatest(coalesce(p_limit, 25), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$function$;

revoke all on function public.branch_reviews(text, integer, integer) from public, anon, authenticated, service_role, washup_vendor_panel;
grant execute on function public.branch_reviews(text, integer, integer) to anon, authenticated, service_role;
