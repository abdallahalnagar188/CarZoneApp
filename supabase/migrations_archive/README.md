# Archived migrations — history only, never run

These files built the production database before 2026-11-26. Their combined result is
`../migrations/20261127120000_baseline_production_schema.sql`; they stay here unchanged so `git log` / `git blame`
and the audit references (`MC/…`, `VM/…` in `docs/system-audit`) keep working. **Do not run or copy any of them
into `migrations/`.** Replaying them is not deterministic and would undo security fixes (GAP-007):

- Three versions exist in both folders with different bodies: `20261020120000`, `20261101120000`, `20261103120000`.
- `panels/20261020120000_hosted_customer_app_objects.sql` is a capture of objects created in the dashboard; it
  re-creates the old insecure `sync_customer_profile`, customer write policies and anon grants.
- `panels/20261101120000_ledger_on_complete.sql` and `panels/20261103120000_review_unique_and_readable_cancel_reasons.sql`
  were never applied (customer-app `docs/portal-fixes.md` W18).
- `customer-app/20261015140000_multi_tenant_and_roles_schema.sql` and `customer-app/20261015140200_realtime_and_indexes.sql`
  never reached production. The first defines a second role/finance model with bank accounts and no RLS (GAP-026).
- The base schema (8 versions `20261015163226`–`20261015163539`: foundation … mobile_apps) came from the old
  carZone repo and has no file here; `20261127100000 revoke_is_staff_or_admin` was applied without a file.

| Folder | From | How it was applied |
|---|---|---|
| `customer-app/` | this repo's `supabase/migrations` (25 files) | mostly `supabase db query --linked -f` (not recorded); some recorded later |
| `panels/` | `washup-vendor/supabase/migrations` (19 files; its pending `20261118120000` moved to `migrations/` as `20261127130000`) + `washup-superadmin/docs/db` (1 file) | SQL editor / `vendor/supabase/apply-migrations.mjs`, recorded |

The versions that were recorded in `supabase_migrations.schema_migrations` before the baseline are kept in
`supabase_migrations.schema_migrations_pre_baseline` on production.
