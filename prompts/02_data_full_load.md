# Prompt 02 — Phase 2B: full data load

Read CLAUDE.md and `01_data/PLAN.md`. Prompt 01 must be done (1% test passing).

1. Check free disk space (`df -h ~`); at least 15 GB is needed. If less, stop and tell me.
2. Re-apply `00_ddl/ddl_v2.sql` to `tech_shop` (`-h localhost -v ON_ERROR_STOP=1`) so it starts empty.
3. Start the load in the background from the project root:
   `nohup psql -U postgres -h localhost -d tech_shop -v scale=1 -f 01_data/run_all.sql > 01_data/logs/run_full.log 2>&1 &`
4. Check progress every few minutes with `grep -E "== |NOTICE|ERROR" 01_data/logs/run_full.log | tail`. If an error appears, stop and show it to me.
5. When it prints `== готово`, run `psql -U postgres -h localhost -d tech_shop -f 01_data/verify.sql > 01_data/logs/verify_full.txt 2>&1`. All integrity checks must be 0, and there must be at least 3 tables ≥ 10,000,000 and 3 tables ≥ 1,000,000 rows.
6. Docs per CLAUDE.md: fill `docs/02b_podatoci_i_pogledi.md` sections 2–4 with the real numbers (row counts per table, database size, duration per script from the log timestamps, the integrity and realism results from verify_full.txt as code blocks). Update `docs/CHANGELOG.md` and the status table in CLAUDE.md and docs/README.md. Commit and push.
7. Ask me before dropping `tech_shop_test`.

Reply briefly: total duration, row counts of the big tables, database size, verify result.
