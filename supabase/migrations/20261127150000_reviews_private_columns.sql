-- PENDING — do NOT apply until the customer-app release that reads the branch page through
-- public.branch_reviews() (20261127143000) is the minimum supported version (force update). Older builds read
-- reviews with select=* as anon / any customer and would show no reviews on a wash page after this.
--
-- GAP-062 (system audit), part 2 — stage 2 of 2: reviews are no longer world-readable.
--   * anon loses SELECT on public.reviews (guests see reviews through branch_reviews()).
--   * a signed-in customer reads only their own reviews ("my reviews", the order's review); every wash page goes
--     through branch_reviews(), which never returns customer_id, reported_by_wash, report_reason or hidden_reason.
--   * the panels are unaffected (postgres / washup_vendor_panel policies).
--
-- Verify (rolled back): as anon "select count(*) from reviews" fails (42501); as a customer only own rows; as
-- anon "select * from branch_reviews('<branch>')" still works.

drop policy if exists "Public read visible reviews" on public.reviews;

create policy "Customers read own reviews" on public.reviews
  as permissive for select to authenticated
  using (customer_id = (select public.current_customer_id()));

revoke select on table public.reviews from anon;
