-- =====================================================================
--  Генерирање на сите податоци (Фаза 2Б)
--  Се пушта од КОРЕНОТ на проектот (поради \copy патеките):
--    psql -U postgres -h localhost -d tech_shop -v scale=1 -f 01_data/run_all.sql
--  scale=0.01 → 1% од обемот за брз тест (~1 мин).
--  Пред пуштање, базата треба да има празна шема од 00_ddl/ddl_v2.sql.
-- =====================================================================
\set ON_ERROR_STOP on
\if :{?scale}
\else
  \set scale 1
\endif
\echo '== run_all.sql, scale =' :scale `date +%T`
\timing on

SET synchronous_commit = off;     -- побрзо вметнување; важи само за оваа сесија
SET work_mem = '256MB';
SET maintenance_work_mem = '1GB';

-- Повторливост: се празнат сите табели на апликацијата
TRUNCATE role, permission, role_permission, employee, employee_role, customer, customer_attribute,
         address, address_customer, supplier, category, product, product_attribute, product_supplier,
         price_history, promotion, shipping, orders, installments, order_item, warehouse, serial_number,
         review, returns, customer_support_report, wishlist, wishlist_items
RESTART IDENTITY CASCADE;

\ir 00_seed_schema.sql
\ir 01_admin.sql
\ir 02_catalog.sql
\ir 03_pricing.sql
\ir 04_customers.sql
\ir 05_orders_stage.sql
\ir 06_orders_load.sql
\ir 07_installments.sql
\ir 08_serial_numbers.sql
\ir 09_after_sales.sql
\ir 10_wishlists.sql
\ir 11_finalize.sql

\echo '== готово' `date +%T`
SELECT relname AS табела, n_live_tup AS редици
FROM pg_stat_user_tables WHERE schemaname = 'public' ORDER BY n_live_tup DESC;
SELECT pg_size_pretty(pg_database_size(current_database())) AS големина_на_базата;
