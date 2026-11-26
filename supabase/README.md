# WASH UP database (Supabase project `tbcmgdwzarfdgzzmmele`)

**This folder is the only source of truth for the database schema** of every WASH UP app: this customer app,
the partner portal (`washup-vendor`), the Super Admin (`washup-superadmin`) and the owner app (through the
portal API). The portals keep no migrations of their own any more (GAP-007, decided 2026-11-26).

| Path | What |
|---|---|
| `migrations/` | The schema history the Supabase CLI runs. Starts with `20261127120000_baseline_production_schema.sql` (the whole live schema on 2026-11-26), then one file per change. |
| `migrations_archive/` | Every older migration file from this repo and from the portals, kept unchanged for history. **Never run them** — see its README. |
| `tests/` | SQL tests that run in one transaction and roll back (e.g. the vendor tenant-role test, GAP-027). |
| `scripts/baseline-gen.sql` | The catalog query that produced the baseline (run in the SQL editor, read-only). |
| `scripts/check-migrations.mjs` | CI guard: unique, well-formed versions, nothing older than the baseline, no stray files. |
| `functions/` | Edge functions (`send-push`, `send-sms-whatsapp`, `share-wash`). |
| `database.types.ts` | TypeScript types generated from the live schema (GAP-059). Regenerate after every migration. |
| `seed-parts/` | Demo / reference data. Not part of the schema. |

## Changing the schema

1. Add `migrations/<UTC yyyymmddHHMMSS>_<snake_case>.sql` — a version later than every file in the folder
   (`node supabase/scripts/check-migrations.mjs` must pass). One change per file; say in a header comment what it
   does, which GAP / ticket, and how to verify it.
2. Write it so it can run once on production: guard data rewrites, never `drop … cascade` blindly. Data fixes and
   one-off cleanups are **not** migrations: put them in a reviewed script outside `migrations/`.
3. If a portal writes a new table or column, add the GRANT + policy for `washup_vendor_panel` in the same migration
   and re-run `tests/20261127110000_vendor_panel_tenant_role.test.sql` (it must say `0 failed`).
4. Apply it to production through the history, never as ad-hoc DDL in the dashboard:
   - CLI: `supabase link --project-ref tbcmgdwzarfdgzzmmele`, then `supabase db push` (runs only versions that are
     not recorded yet).
   - Or the SQL editor: run the file, then
     `insert into supabase_migrations.schema_migrations (version, name) values ('<version>', '<name>');`
5. Regenerate the types (`supabase gen types typescript --project-id tbcmgdwzarfdgzzmmele > supabase/database.types.ts`,
   or Dashboard → Integrations → Data API → Docs → "Generate and download types") and commit them with the migration.
6. Tell the other apps' developers: the portals and the owner app read this schema too.

CI (`.github/workflows/db.yml`): `check-migrations.mjs` on every change under `supabase/`, and — when the repository
secret `SUPABASE_ACCESS_TOKEN` is set — a weekly / per-PR diff of `database.types.ts` against the live schema, which
also catches DDL run in the dashboard outside this folder.

## State of production (2026-11-26)

- `supabase_migrations.schema_migrations` holds `20261127120000 baseline_production_schema` and later versions only.
  The rows recorded before the baseline (carZone's 8 foundation versions, the portals' and this app's migrations)
  were copied to `supabase_migrations.schema_migrations_pre_baseline` and removed, so the CLI sees one history.
- Pending (in `migrations/`, not applied yet): `20261127130000_application_documents_bucket.sql` (GAP-001: adds
  `image/webp` to the private KYC bucket; the upload route already accepts WebP).
- Outside the schema and set by hand on a new project: Vault secrets, Auth settings, edge-function deploys and
  secrets, storage objects, reference data. The baseline header lists them.

## A new environment (staging, preview, disaster recovery)

Create a Supabase project, `supabase link --project-ref <new ref>`, `supabase db push` (baseline + later files),
deploy the edge functions, create the Vault secrets and Auth settings, then load reference data. The baseline was
verified by replaying it on production into a scratch schema (rolled back); it has not yet been run on an empty
project — the first staging project is that test.
