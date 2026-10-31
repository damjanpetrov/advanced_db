-- =====================================================================
--  04 — Купувачи, адреси, атрибути
--  * купувачите се од seed.person_pool → име+презиме уникатно, email уникатен
--  * customer_id расте со датумот на регистрација (2020-06 … 2026-09), со забрзување:
--    t = T × (i/N)^0,62 → повеќе регистрации подоцна
--  * телефон: seed.mobile() → уникатен по конструкција (10% немаат телефон)
--  * адреса: уникатна (држава, град, улица, број) — види чекор 2
-- =====================================================================
\echo '== 04_customers.sql' `date +%T`
SELECT setseed(0.404);
SELECT count(*) AS n_customers FROM seed.person_pool WHERE NOT is_employee \gset

INSERT INTO customer (customer_id, name, surname, email, password, phone, created_at, is_active)
SELECT p.customer_id, p.name, p.surname,
       p.name_lat || '.' || p.surname_lat || '@' || ed.domain,
       '$2b$12$' || substr(md5('c' || p.customer_id) || md5('p' || p.customer_id), 1, 53),
       CASE WHEN p.r_phone < 0.10 THEN NULL
            ELSE seed.mobile(p.grp, row_number() OVER (PARTITION BY g.addr_grp ORDER BY p.customer_id), p.r_phone > 0.25) END,
       timestamp '2020-06-01' + power(p.customer_id::float / :n_customers, 0.62) * (timestamp '2026-09-30' - timestamp '2020-06-01'),
       random() > 0.03
FROM (SELECT pp.*, random() AS r_phone, random() AS r_dom FROM seed.person_pool pp WHERE NOT is_employee) p
JOIN seed.groups g ON g.grp = p.grp
JOIN seed.email_domains ed ON ed.id = 1 + floor(p.r_dom * 10)::int;

-- 1. План на адреси: примарна (address_id = customer_id) + втора за 5% (address_id = N + k)
CREATE TABLE seed.second_address AS
SELECT customer_id, :n_customers + row_number() OVER (ORDER BY customer_id) AS address_id
FROM customer WHERE random() < 0.05;
ALTER TABLE seed.second_address ADD PRIMARY KEY (customer_id);

CREATE TABLE seed.addr_plan AS
SELECT a.address_id, a.customer_id, g.addr_grp, g.country,
       c.city
FROM (
    SELECT customer_id AS address_id, customer_id, random() AS r_city FROM customer
    UNION ALL
    SELECT address_id, customer_id, random() FROM seed.second_address
) a
JOIN seed.person_pool p ON p.customer_id = a.customer_id
JOIN seed.groups g      ON g.grp = p.grp
JOIN seed.grp_size gs   ON gs.grp = g.addr_grp
JOIN seed.pick_city c   ON c.grp = g.addr_grp AND c.id = 1 + floor(a.r_city * gs.n_city);

-- 2. Уникатни адреси по конструкција: во секој град адресите добиваат случаен реден број k,
--    а k се пресликува во (улица, куќен број, стан): улица = k mod S, број = пермутација од (k / S) mod 150,
--    стан = k / (S × 150). Различен k → различна комбинација → нема двајца со иста адреса.
INSERT INTO address (address_id, street, number, city, country)
SELECT x.address_id, st.street,
       (((((x.k / gs.n_street) % 150) * 7 + 3) % 150) + 1)::text   -- пермутација на 1..150 (7 и 150 се заемно прости)
           || CASE WHEN x.k / (gs.n_street * 150) > 0 THEN '/' || (x.k / (gs.n_street * 150)) ELSE '' END,
       x.city, x.country
FROM (
    SELECT ap.*, row_number() OVER (PARTITION BY ap.addr_grp, ap.city ORDER BY random()) - 1 AS k
    FROM seed.addr_plan ap
) x
JOIN seed.grp_size gs  ON gs.grp = x.addr_grp
JOIN seed.pick_street st ON st.grp = x.addr_grp AND st.id = 1 + x.k % gs.n_street;

INSERT INTO address_customer (customer_id, address_id)
SELECT customer_id, address_id FROM seed.addr_plan;
DROP TABLE seed.addr_plan;

-- Атрибути: 20% купувачи имаат 2 атрибути
INSERT INTO customer_attribute (name, text, customer_id)
SELECT a.name, a.val, c.customer_id
FROM (SELECT customer_id FROM customer WHERE random() < 0.20) c
CROSS JOIN LATERAL (VALUES
    ('newsletter', CASE WHEN random() < 0.6 THEN 'да' ELSE 'не' END),
    ('preferred_payment', (ARRAY['card','cash_on_delivery','installments'])[1 + floor(random() * 3)::int])
) a(name, val);

-- За секој ден: највисокиот customer_id регистриран ПРЕД тој ден.
-- Нарачка на ден d бира купувач само од [1, max_id(d)] → никој не нарачува пред регистрација.
CREATE TABLE seed.customer_by_day AS
WITH daily AS (SELECT created_at::date AS day, max(customer_id) AS mx FROM customer GROUP BY 1),
     run   AS (SELECT day, max(mx) OVER (ORDER BY day) AS mx FROM daily)
SELECT c.day,
       coalesce((SELECT r.mx FROM run r WHERE r.day < c.day ORDER BY r.day DESC LIMIT 1), 1) AS max_id
FROM seed.calendar c;
ALTER TABLE seed.customer_by_day ADD PRIMARY KEY (day);
