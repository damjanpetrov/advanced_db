# Prompt 00 — Setup check (Phase 2A)

Read CLAUDE.md first and follow it.

Goal: verify that the database access works and bring the Phase 2A documentation up to date with results from the real local database.

Steps:

1. Check the connection to the server: `psql -U postgres -h localhost -d postgres -c "select version(), inet_server_port();"` — must be PostgreSQL 18.x on port 5432 (the same server DataGrip uses). Use `-h localhost` in every psql/createdb command. If `psql` is not on PATH, use `/Library/PostgreSQL/18/bin/psql`. If the connection fails, stop and tell me the exact error.
   If database `tech_shop` does not exist, create it: `createdb -U postgres -h localhost tech_shop`.
   Add `-h localhost` to the "Database access" examples in CLAUDE.md.
2. Run `00_ddl/ddl_v2.sql` on `tech_shop` with `ON_ERROR_STOP=1`. Confirm 27 tables in schema `public`.
3. Run `00_ddl/constraint_tests.sql` and save the PASS/FAIL lines to `00_ddl/constraint_tests_output.txt`, keeping a first line with the PostgreSQL version and today's date. All 48 must PASS; if any FAIL, stop and explain.
4. Regenerate `docs/data_dictionary.md` with `scripts/data_dictionary.sql`.
5. Update `docs/02a_ddl.md`, section 7: replace the sandbox result with the result on the local PostgreSQL version.
6. Add an entry to `docs/CHANGELOG.md`.
7. Commit the changes to git (the repository already exists). Add `.Rhistory` to `.gitignore`.

Reply briefly: PostgreSQL version, table count, test result, files changed.
