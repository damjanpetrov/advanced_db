-- =====================================================================
--  Проверки на генерираните податоци. Секоја проверка за интегритет мора да врати 0.
--  psql -U postgres -h localhost -d tech_shop -f 01_data/verify.sql
-- =====================================================================
\pset footer off
\echo '== 1. Број на редици'
SELECT relname AS табела, n_live_tup AS редици,
       CASE WHEN n_live_tup >= 10000000 THEN '10M+' WHEN n_live_tup >= 1000000 THEN '1M+' ELSE '' END AS класа
FROM pg_stat_user_tables WHERE schemaname = 'public' ORDER BY n_live_tup DESC;

\echo '== 2. Интегритет (очекувано: 0 насекаде)'
SELECT 'износ на нарачка ≠ збир на ставки' AS проверка, count(*) AS грешки FROM (
    SELECT o.order_id FROM orders o JOIN order_item i ON i.order_id = o.order_id
    GROUP BY o.order_id, o.amount HAVING o.amount <> sum(i.quantity * i.unit_price)) x
UNION ALL
SELECT 'ставка (не откажана) без точно quantity сериски', count(*) FROM (
    SELECT i.order_item_id FROM order_item i LEFT JOIN serial_number s ON s.order_item_id = i.order_item_id
    WHERE i.status <> 'cancelled' GROUP BY i.order_item_id, i.quantity HAVING count(s.serial_number_id) <> i.quantity) x
UNION ALL
SELECT 'сериски врзан за откажана ставка', count(*)
FROM serial_number s JOIN order_item i ON i.order_item_id = s.order_item_id WHERE i.status = 'cancelled'
UNION ALL
SELECT 'сериски примен по датумот на нарачката', count(*)
FROM serial_number s JOIN order_item i ON i.order_item_id = s.order_item_id JOIN orders o ON o.order_id = i.order_id
WHERE s.received_at > o.date_ordered
UNION ALL
SELECT 'нарачка пред регистрацијата на купувачот', count(*)
FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.date_ordered < c.created_at
UNION ALL
SELECT 'ставка со производ што не постоел на датумот', count(*)
FROM order_item i JOIN orders o ON o.order_id = i.order_id JOIN product p ON p.product_id = i.product_id
WHERE p.created_at > o.date_ordered
UNION ALL
SELECT 'рецензија за ставка што не е доставена', count(*)
FROM review r JOIN order_item i ON i.order_item_id = r.order_item_id WHERE i.status <> 'delivered'
UNION ALL
SELECT 'рецензија пред доставата', count(*)
FROM review r JOIN order_item i ON i.order_item_id = r.order_item_id JOIN shipping s ON s.shipping_id = i.order_id
WHERE r.date < s.delivered_date
UNION ALL
SELECT 'враќање за ставка што не е доставена', count(*)
FROM returns r JOIN order_item i ON i.order_item_id = r.order_item_id WHERE i.status <> 'delivered'
UNION ALL
SELECT 'збир на рати ≠ износ на нарачката', count(*) FROM (
    SELECT o.order_id FROM orders o JOIN installments t ON t.order_id = o.order_id
    GROUP BY o.order_id, o.amount HAVING sum(t.amount) <> o.amount) x
UNION ALL
SELECT 'нарачка на рати без рати', count(*)
FROM orders o WHERE o.method_payment = 'installments' AND o.date_paid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM installments t WHERE t.order_id = o.order_id)
UNION ALL
SELECT 'доставена пратка со нарачка што не е доставена', count(*)
FROM orders o JOIN shipping s ON s.shipping_id = o.shipping_id
WHERE s.status = 'delivered' AND o.status NOT IN ('delivered')
UNION ALL
SELECT 'нарачки по 2026-09-30', count(*) FROM orders WHERE date_ordered >= '2026-10-01'
UNION ALL
SELECT 'исто име и презиме кај двајца луѓе (купувачи + вработени)', count(*) FROM (
    SELECT name, surname FROM (SELECT name, surname FROM customer UNION ALL SELECT name, surname FROM employee) p
    GROUP BY name, surname HAVING count(*) > 1) x
UNION ALL
SELECT 'ист email кај двајца луѓе', count(*) FROM (
    SELECT lower(email) FROM (SELECT email FROM customer UNION ALL SELECT email FROM employee) p
    GROUP BY 1 HAVING count(*) > 1) x
UNION ALL
SELECT 'ист телефон кај двајца луѓе (вклучува +389 = 0 форма)', count(*) FROM (
    SELECT regexp_replace(phone, '^(\+389|0)', '389') FROM (SELECT phone FROM customer UNION ALL SELECT phone FROM employee) p
    WHERE phone IS NOT NULL GROUP BY 1 HAVING count(*) > 1) x
UNION ALL
SELECT 'иста адреса (држава, град, улица, број) кај две адреси', count(*) FROM (
    SELECT country, city, street, number FROM address GROUP BY 1, 2, 3, 4 HAVING count(*) > 1) x
UNION ALL
SELECT 'адреса врзана за повеќе од еден купувач', count(*) FROM (
    SELECT address_id FROM address_customer GROUP BY 1 HAVING count(*) > 1) x;

\echo '== 3. Реалистичност'
\echo '-- нарачки по година и удел на ноември+декември'
SELECT extract(year FROM date_ordered)::int AS година, count(*) AS нарачки,
       round(100.0 * count(*) FILTER (WHERE extract(month FROM date_ordered) IN (11, 12)) / count(*), 1) AS "% ное+дек",
       round(avg(amount), 0) AS просечен_износ
FROM orders GROUP BY 1 ORDER BY 1;

\echo '-- статус и начин на плаќање (%)'
SELECT status, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS "%" FROM orders GROUP BY 1 ORDER BY 2 DESC;
SELECT method_payment, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS "%" FROM orders GROUP BY 1 ORDER BY 2 DESC;

\echo '-- нарачки по час (врв очекуван 19–22 ч)'
SELECT extract(hour FROM date_ordered)::int AS час, count(*) AS нарачки FROM orders GROUP BY 1 ORDER BY 1;

\echo '-- Парето: удел на топ 20% производи во продадените парчиња (очекувано 70–85%)'
WITH u AS (SELECT product_id, sum(quantity) AS units FROM order_item WHERE status <> 'cancelled' GROUP BY 1),
     r AS (SELECT units, ntile(5) OVER (ORDER BY units DESC) AS q FROM u)
SELECT round(100.0 * sum(units) FILTER (WHERE q = 1) / sum(units), 1) AS "% од топ 20%" FROM r;

\echo '-- оценки на рецензии (%)'
SELECT rating, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS "%" FROM review GROUP BY 1 ORDER BY 1 DESC;

\echo '-- статус на сериски броеви'
SELECT status, count(*) FROM serial_number GROUP BY 1 ORDER BY 2 DESC;

\echo '-- купувачи по држава'
SELECT a.country, count(*) AS купувачи, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS "%"
FROM customer c JOIN address a ON a.address_id = c.customer_id GROUP BY 1 ORDER BY 2 DESC;
\echo '-- примерок купувачи'
SELECT c.name, c.surname, c.email, c.phone, a.street || ' ' || a.number || ', ' || a.city || ', ' || a.country AS адреса
FROM customer c JOIN address a ON a.address_id = c.customer_id ORDER BY c.customer_id LIMIT 10;

\echo '== 4. Големина'
SELECT pg_size_pretty(pg_database_size(current_database())) AS база;
