-- =====================================================================
--  03 — Цени и акции
--  Цената се менува квартално: модел поевтинува ~1% по квартал,
--  со шум ±3% и поскапување во 2022 (инфлација). Секоја промена е ред во
--  price_history; product.price е последната цена.
-- =====================================================================
\echo '== 03_pricing.sql' `date +%T`
SELECT setseed(0.303);

-- Цена по производ по квартал (од кварталот на излегување до Q3 2026)
CREATE TABLE seed.product_quarter_price AS
WITH q AS (
    SELECT p.product_id, p.price AS launch_price, p.created_at,
           qs::date AS quarter_start,
           -- логаритамска промена на цената за овој квартал
           CASE WHEN qs::date = date_trunc('quarter', p.created_at)::date THEN 0
                ELSE -0.01 + (random() - 0.5) * 0.06
                     + CASE WHEN qs::date BETWEEN '2022-04-01' AND '2022-12-31' THEN 0.04 ELSE 0 END
           END AS dlog
    FROM product p
    CROSS JOIN LATERAL generate_series(date_trunc('quarter', p.created_at), timestamp '2026-07-01', interval '3 months') qs
)
SELECT product_id, quarter_start,
       -- психолошка цена: заокружено на стотка минус 10 (пр. 54.990)
       greatest(round((launch_price * exp(sum(dlog) OVER (PARTITION BY product_id ORDER BY quarter_start)))::numeric, -2) - 10, 290)::numeric(10,2) AS price,
       created_at
FROM q;
ALTER TABLE seed.product_quarter_price ADD PRIMARY KEY (product_id, quarter_start);

-- price_history: првиот ред е на датумот на излегување, потоа почеток на секој квартал
INSERT INTO price_history (date, price, product_id)
SELECT CASE WHEN quarter_start = date_trunc('quarter', created_at)::date THEN created_at::date ELSE quarter_start END,
       price, product_id
FROM seed.product_quarter_price;

-- Тековна цена = последниот квартал
UPDATE product p SET price = q.price
FROM seed.product_quarter_price q
WHERE q.product_id = p.product_id AND q.quarter_start = date '2026-07-01';

-- Акции 1: Black Friday недела (2021–2025) за ~25% од производите, 15–35%
INSERT INTO promotion (percent, start_date, end_date, product_id)
SELECT round((15 + random() * 20)::numeric, 0), bf - 3, bf + 3, p.product_id
FROM generate_series(2021, 2025) y
CROSS JOIN LATERAL (SELECT make_date(y, 11, 1) + ((4 - extract(isodow FROM make_date(y, 11, 1))::int + 7) % 7) + 22 AS bf) b
JOIN product p ON p.created_at < (b.bf - 3)
WHERE random() < 0.25;

-- Акции 2: редовна акција 5–20%, 5–14 дена, во февруари–октомври (не се преклопува со Black Friday)
INSERT INTO promotion (percent, start_date, end_date, product_id)
SELECT pct, s, s + len, product_id
FROM (
    SELECT p.product_id,
           round((5 + random() * 15)::numeric, 0) AS pct,
           (make_date(y, 2, 1) + floor(random() * 250)::int) AS s,
           5 + floor(random() * 10)::int AS len,
           p.created_at
    FROM generate_series(2021, 2026) y
    CROSS JOIN product p
    WHERE random() < 0.30
) x
WHERE s > created_at::date;
