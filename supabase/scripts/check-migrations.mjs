#!/usr/bin/env node
// GAP-007 guard: supabase/migrations is the only schema history of the WASH UP database.
// Fails (exit 1) when a file name is not `<14-digit version>_<snake_case>.sql`, a version repeats, a file is
// older than the baseline, or something that is not a migration (tests, captures, notes) sits in the folder.
// Usage: node supabase/scripts/check-migrations.mjs   (from the repo root; no dependencies)
import { readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const BASELINE = "20261127120000";
const dir = join(dirname(fileURLToPath(import.meta.url)), "..", "migrations");
const files = readdirSync(dir).sort();
const problems = [];
const seen = new Map();

for (const file of files) {
  const match = /^(\d{14})_([a-z0-9_]+)\.sql$/.exec(file);
  if (!match) {
    problems.push(`${file}: not <version>_<snake_case>.sql (tests go to supabase/tests/, notes to the README)`);
    continue;
  }
  const [, version] = match;
  if (seen.has(version)) problems.push(`${file}: version ${version} already used by ${seen.get(version)}`);
  seen.set(version, file);
  if (version < BASELINE) problems.push(`${file}: older than the baseline ${BASELINE} (history lives in migrations_archive/)`);
}
if (!seen.has(BASELINE)) problems.push(`baseline ${BASELINE}_*.sql is missing`);

if (problems.length) {
  console.error(`check-migrations: ${problems.length} problem(s)\n- ${problems.join("\n- ")}`);
  process.exit(1);
}
console.log(`check-migrations: ${files.length} migration(s), versions unique, baseline ${BASELINE} first`);
