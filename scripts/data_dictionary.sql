-- =====================================================================
--  Generates docs/data_dictionary.md from the live database catalog.
--  Usage (from project root):
--    psql -d tech_shop -X -A -t -q -f scripts/data_dictionary.sql -o docs/data_dictionary.md
--  Re-run after EVERY schema change.
-- =====================================================================
WITH cols AS (
    SELECT c.table_name, c.ordinal_position, c.column_name,
           CASE WHEN c.data_type = 'character varying' THEN 'varchar(' || c.character_maximum_length || ')'
                WHEN c.data_type = 'numeric' AND c.numeric_precision IS NOT NULL
                     THEN 'numeric(' || c.numeric_precision || ',' || c.numeric_scale || ')'
                WHEN c.data_type LIKE 'timestamp%' THEN 'timestamp'
                ELSE c.data_type END AS type,
           CASE WHEN c.is_nullable = 'NO' THEN 'да' ELSE '' END AS not_null,
           CASE WHEN c.is_identity = 'YES' THEN 'identity'
                ELSE coalesce(replace(c.column_default, '|', '\|'), '') END AS dflt
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
),
cons AS (
    SELECT rel.relname AS table_name, con.conname,
           CASE con.contype WHEN 'p' THEN 'PK' WHEN 'f' THEN 'FK' WHEN 'u' THEN 'UNIQUE'
                            WHEN 'c' THEN 'CHECK' ELSE con.contype::text END AS kind,
           replace(pg_get_constraintdef(con.oid), '|', '\|') AS def
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = rel.relnamespace
    WHERE n.nspname = 'public'
    UNION ALL
    SELECT t.relname, i.relname, 'UNIQUE INDEX', replace(pg_get_indexdef(i.oid), '|', '\|')
    FROM pg_index x
    JOIN pg_class i ON i.oid = x.indexrelid
    JOIN pg_class t ON t.oid = x.indrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public' AND x.indisunique
      AND NOT EXISTS (SELECT 1 FROM pg_constraint c WHERE c.conindid = i.oid)
),
tbl AS (
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
)
SELECT '# Речник на податоци (data dictionary)' || E'\n\n'
    || '> Автоматски генерирано од базата со `scripts/data_dictionary.sql` на '
    || to_char(now(), 'YYYY-MM-DD HH24:MI') || '. Не уредувај рачно.' || E'\n\n'
    || 'Вкупно табели: ' || (SELECT count(*) FROM tbl) || E'\n\n'
    || string_agg(section, E'\n' ORDER BY table_name)
FROM (
    SELECT t.table_name,
           '## ' || t.table_name || E'\n\n'
        || coalesce('_' || obj_description(('public.' || quote_ident(t.table_name))::regclass, 'pg_class') || '_' || E'\n\n', '')
        || '| # | Колона | Тип | NOT NULL | Default |' || E'\n'
        || '| --- | --- | --- | --- | --- |' || E'\n'
        || (SELECT string_agg('| ' || ordinal_position || ' | `' || column_name || '` | ' || type || ' | '
                              || not_null || ' | ' || dflt || ' |', E'\n' ORDER BY ordinal_position)
            FROM cols c WHERE c.table_name = t.table_name) || E'\n\n'
        || '| Ограничување | Тип | Дефиниција |' || E'\n'
        || '| --- | --- | --- |' || E'\n'
        || coalesce((SELECT string_agg('| `' || conname || '` | ' || kind || ' | `' || def || '` |', E'\n'
                                       ORDER BY CASE kind WHEN 'PK' THEN 1 WHEN 'FK' THEN 2 WHEN 'UNIQUE' THEN 3
                                                          WHEN 'UNIQUE INDEX' THEN 4 ELSE 5 END, conname)
                     FROM cons k WHERE k.table_name = t.table_name), '') || E'\n'
           AS section
    FROM tbl t
) s;
