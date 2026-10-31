# Prompt 01 — Phase 2B: test the data generation scripts at 1%

Read CLAUDE.md and `01_data/PLAN.md`. The generation scripts in `01_data/` are already written and were tested on PostgreSQL 16 (all 18 integrity and uniqueness checks pass). Your job is to run them on our local PostgreSQL 18 at 1% scale and confirm. Do not rewrite them; if something fails on PG 18, make the minimal fix, explain it, and note it in the script with a comment.

All commands run from the project root (the `\copy` paths are relative to it). Use `-h localhost`.

1. `createdb -U postgres -h localhost tech_shop_test` (if missing), then apply `00_ddl/ddl_v2.sql` to it with `-v ON_ERROR_STOP=1`. Note: `ddl_v2.sql` changed (customer phone now allows international E.164 numbers, migration `00_ddl/001_customer_phone_international.sql`). Also apply that migration to `tech_shop`, re-run `00_ddl/constraint_tests.sql` there (must stay 48/48) and regenerate `docs/data_dictionary.md`.
2. `mkdir -p 01_data/logs` and add `01_data/logs/` to `.gitignore`.
3. `psql -U postgres -h localhost -d tech_shop_test -v scale=0.01 -f 01_data/run_all.sql > 01_data/logs/run_test.log 2>&1`, then check the log for errors.
4. `psql -U postgres -h localhost -d tech_shop_test -f 01_data/verify.sql > 01_data/logs/verify_test.txt 2>&1`. Every integrity and uniqueness check must be 0 (no duplicate name+surname, email, phone or address).
5. Report: total duration of the run (first and last `==` timestamps in the log), database size, and free disk space (`df -h ~`). Estimate the full run as ~100× the duration of scripts 04–10.
6. Do NOT touch the `tech_shop` database.
7. Docs per CLAUDE.md: `docs/02b_podatoci_i_pogledi.md` section 1 (approach and techniques — summarise PLAN.md §2–3, no final numbers yet), `docs/CHANGELOG.md`. Commit.

Reply briefly: pass/fail of the integrity checks, run time, size, free disk, estimate for the full run.
