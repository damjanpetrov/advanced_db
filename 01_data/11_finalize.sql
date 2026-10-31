-- =====================================================================
--  11 — Завршување: секвенците по експлицитните ID-а, бришење staging, статистики
-- =====================================================================
\echo '== 11_finalize.sql' `date +%T`

-- IDENTITY секвенците да продолжат по највисокиот ID (вметнувавме експлицитни вредности)
DO $$
DECLARE r record; mx bigint;
BEGIN
    FOR r IN SELECT table_name, column_name FROM information_schema.columns
             WHERE table_schema = 'public' AND is_identity = 'YES' LOOP
        EXECUTE format('SELECT max(%I) FROM public.%I', r.column_name, r.table_name) INTO mx;
        PERFORM setval(pg_get_serial_sequence('public.' || quote_ident(r.table_name), r.column_name), coalesce(mx, 0) + 1, false);
    END LOOP;
END $$;

-- staging табелите повеќе не се потребни; lookup табелите во seed остануваат
DROP TABLE IF EXISTS seed.stg_orders, seed.stg_items, seed.stg_orders_final, seed.day_counts;
DROP PROCEDURE IF EXISTS seed.load_orders(), seed.load_serials();

VACUUM ANALYZE;
