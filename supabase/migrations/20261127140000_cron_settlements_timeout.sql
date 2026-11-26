-- GAP-060 (system audit): statement_timeout and scheduled jobs.
--
-- The postgres role carries statement_timeout = 30s and idle_in_transaction_session_timeout = 60s. That role is
-- what both panels connect as (DATABASE_URL) and what pg_cron runs every job as, so the 30 s is the panels' only
-- guard against a runaway query — it stays (decision 2026-11-26). Measured on production: close-stale-orders
-- runs in at most 0.32 s (5192 runs) and refresh-offer-statuses in 0.19 s (9243 runs), never failed.
-- The weekly generate-settlements job (not run yet) scans a week of ledger rows and grows with traffic, so it
-- gets its own limit in the job command instead of inheriting the 30 s.
--
-- Migrations: long ones start with "set statement_timeout = 0;" (the baseline does); see supabase/README.md.
-- The data fixes the audit found inside old migrations now live only in migrations_archive/ (never replayed).
--
-- Verify: select command from cron.job where jobname = 'generate-settlements';

select cron.schedule(
  'generate-settlements',
  '0 3 * * 1',
  $job$set statement_timeout = '5min'; select public.generate_settlements(current_date - 7, current_date - 1)$job$
);
