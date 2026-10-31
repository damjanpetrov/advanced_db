# Prompt 01 — Phase 2B: data generation scripts + 1% test

Read CLAUDE.md and `01_data/PLAN.md` first. The plan is the specification; follow it. If something in the plan is impossible or contradicts the schema, stop and tell me instead of improvising.

Reference material (style only, not our schema): the auditory exercise approach (staging/temp tables, `COPY` from CSV, `generate_series`, `row_number() over (partition by ... order by random())`, cross joins) and the example project in `_to_delete/reference/AdvDB-master` (numbered seed scripts run by a master script with `\ir`). Do not copy its data files; create our own lookup CSVs.

Do:

1. Create the lookup CSVs in `01_data/csv/` (UTF-8, header row) as described in PLAN §3. Names, surnames, cities and streets must be realistic Macedonian (Cyrillic + Latin transliteration columns). Product templates must be realistic tech products (real brands, plausible model lines and price ranges in MKD or EUR — pick one currency, state it in PLAN.md §5.4).
2. Write `01_data/00_seed_schema.sql` … `11_finalize.sql`, `run_all.sql` and `verify.sql` exactly as listed in PLAN §6, using the `:scale` psql variable everywhere a volume appears. Comment each script in Macedonian (what it generates and why the distribution is realistic).
3. Add `01_data/logs/` to `.gitignore`.
4. Test at 1%:
   - `createdb -U postgres -h localhost tech_shop_test` (if it does not exist);
   - apply `00_ddl/ddl_v2.sql` to it;
   - `psql -U postgres -h localhost -d tech_shop_test -v scale=0.01 -f 01_data/run_all.sql > 01_data/logs/run_test.log 2>&1`;
   - run `verify.sql` and save output to `01_data/logs/verify_test.txt`.
   Fix and re-run until it completes without errors and every check in PLAN §8 passes (counts will be 1% of target).
5. Extrapolate the full-run time and size from the 1% run (`pg_database_size`, timings in the log) and report them. Check free disk with `df -h ~`.
6. Do NOT run the full load. Do NOT touch the `tech_shop` database.
7. Update docs per CLAUDE.md: `docs/02b_podatoci_i_pogledi.md` section 1 (approach, techniques, script order — no final numbers yet), `docs/CHANGELOG.md`. Commit.

Reply briefly: files created, 1% test result (pass/fail per check), estimated full-run time and size, free disk space.
