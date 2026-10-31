-- =====================================================================
--  05 — Нарачки и ставки во staging (UNLOGGED табели во шемата seed)
--  Сè што зависи од повеќе табели (цена на датумот, износ, начин на плаќање,
--  статус, датуми на пратка) се пресметува тука. Потоа во 06 секој ред се
--  вметнува ЕДНАШ во вистинските табели, без UPDATE на милиони редици.
-- =====================================================================
\echo '== 05_orders_stage.sql' `date +%T`
SELECT setseed(0.505);
SELECT (10000000 * :scale)::bigint AS n_orders \gset

-- 1. Број на нарачки по ден според тежината од календарот + почетен order_id за денот
DROP TABLE IF EXISTS seed.day_counts;
CREATE TABLE seed.day_counts AS
WITH w AS (SELECT day, ceil(:n_orders * weight / sum(weight) OVER ())::int AS n FROM seed.calendar)
SELECT day, n, coalesce(sum(n) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)::bigint AS offs
FROM w;

-- 2. Нарачки
DROP TABLE IF EXISTS seed.stg_orders;
CREATE UNLOGGED TABLE seed.stg_orders AS
SELECT o.order_id, o.date_ordered, o.customer_id,
       CASE WHEN sa.address_id IS NOT NULL AND o.r_addr < 0.30 THEN sa.address_id ELSE o.customer_id END AS address_id,
       CASE WHEN o.r_items < 0.80 THEN 1 WHEN o.r_items < 0.95 THEN 2 ELSE 3 END AS n_items,
       -- статус според старост на нарачката (податоците завршуваат на 2026-09-30)
       CASE WHEN o.age > 30 THEN CASE WHEN o.r_status < 0.10 THEN 'cancelled' ELSE 'delivered' END
            WHEN o.age >= 5 THEN CASE WHEN o.r_status < 0.10 THEN 'cancelled' WHEN o.r_status < 0.12 THEN 'shipped' ELSE 'delivered' END
            WHEN o.age >= 2 THEN CASE WHEN o.r_status < 0.10 THEN 'cancelled' WHEN o.r_status < 0.30 THEN 'paid' ELSE 'shipped' END
            ELSE CASE WHEN o.r_status < 0.08 THEN 'cancelled' WHEN o.r_status < 0.45 THEN 'pending' ELSE 'paid' END
       END::varchar(50) AS status,
       o.r_pay, o.r_ship, o.r_dlv, o.r_paid
FROM (
    SELECT x.*, greatest(1, ceil(cb.max_id * power(x.r_cust, 1.3)))::int AS customer_id,
           x.day + make_interval(hours => h.hour) + x.r_min * interval '1 hour' AS date_ordered,
           date '2026-09-30' - x.day AS age
    FROM (
        SELECT d.offs + k AS order_id, d.day,
               random() AS r_hour, random() AS r_min, random() AS r_cust, random() AS r_addr,
               random() AS r_items, random() AS r_status, random() AS r_pay,
               random() AS r_ship, random() AS r_dlv, random() AS r_paid
        FROM seed.day_counts d
        CROSS JOIN LATERAL generate_series(1, d.n) k          -- n е колона → различен број по ден
    ) x
    JOIN seed.customer_by_day cb ON cb.day = x.day
    JOIN seed.pick_hour h ON h.id = 1 + floor(x.r_hour * (SELECT count(*) FROM seed.pick_hour))
) o
LEFT JOIN seed.second_address sa ON sa.customer_id = o.customer_id;
ALTER TABLE seed.stg_orders ADD PRIMARY KEY (order_id);

-- 3. Ставки: Парето избор на производ (rank = N × r^5.5 → топ 20% производи ≈ 75% од продажбата), цена на кварталот, попуст ако има акција
SELECT count(*) AS n_products FROM seed.product_rank \gset
SELECT count(*) AS n_early FROM seed.product_rank_early \gset

DROP TABLE IF EXISTS seed.stg_items;
CREATE UNLOGGED TABLE seed.stg_items AS
WITH picked AS (
    SELECT DISTINCT ON (s.order_id, s.product_id) s.*
    FROM (
        SELECT o.order_id, o.date_ordered, o.status,
               CASE WHEN pr.created_at <= o.date_ordered THEN pr.product_id ELSE pe.product_id END AS product_id,
               CASE WHEN o.r_qty < 0.92 THEN 1 WHEN o.r_qty < 0.98 THEN 2 ELSE 3 END AS quantity
        FROM (
            SELECT so.order_id, so.date_ordered, so.status,
                   1 + floor(:n_products * power(random(), 5.5))::int AS rnk,
                   random() AS r_qty
            FROM seed.stg_orders so
            CROSS JOIN LATERAL generate_series(1, so.n_items) k
        ) o
        JOIN seed.product_rank pr       ON pr.rank = o.rnk
        JOIN seed.product_rank_early pe ON pe.rank = 1 + (o.rnk - 1) % :n_early
    ) s
    ORDER BY s.order_id, s.product_id
)
SELECT row_number() OVER (ORDER BY p.order_id, p.product_id) AS order_item_id,
       p.order_id, p.product_id, p.quantity,
       round(q.price * (1 - coalesce(pm.percent, 0) / 100), 2)::numeric(10,2) AS unit_price,
       CASE p.status WHEN 'delivered' THEN 'delivered' WHEN 'shipped' THEN 'shipped'
                     WHEN 'paid' THEN 'processed' WHEN 'pending' THEN 'pending' ELSE 'cancelled' END::varchar(50) AS status,
       p.date_ordered
FROM picked p
JOIN seed.product_quarter_price q
  ON q.product_id = p.product_id AND q.quarter_start = date_trunc('quarter', p.date_ordered)::date
LEFT JOIN promotion pm
  ON pm.product_id = p.product_id AND p.date_ordered::date BETWEEN pm.start_date AND pm.end_date;

-- 4. Конечни атрибути на нарачката: износ, начин на плаќање, датуми на пратка и плаќање
DROP TABLE IF EXISTS seed.stg_orders_final;
CREATE UNLOGGED TABLE seed.stg_orders_final AS
WITH amt AS (SELECT order_id, sum(quantity * unit_price) AS amount FROM seed.stg_items GROUP BY order_id),
m AS (
    SELECT o.*, a.amount,
           CASE WHEN a.amount >= 15000 THEN
                    CASE WHEN o.r_pay < 0.52 THEN 'card' WHEN o.r_pay < 0.58 THEN 'installments'
                         WHEN o.r_pay < 0.90 THEN 'cash_on_delivery' ELSE 'bank_transfer' END
                ELSE CASE WHEN o.r_pay < 0.58 THEN 'card' WHEN o.r_pay < 0.90 THEN 'cash_on_delivery' ELSE 'bank_transfer' END
           END AS method_payment,
           o.date_ordered::date + floor(o.r_ship * 3)::int AS ship_raw          -- испраќање 0–2 дена по нарачката
    FROM seed.stg_orders o JOIN amt a USING (order_id)
),
s AS (
    SELECT m.*,
           least(ship_raw + CASE extract(isodow FROM ship_raw)::int WHEN 6 THEN 2 WHEN 7 THEN 1 ELSE 0 END,  -- викенд → понеделник
                 date '2026-09-29') AS ship_date
    FROM m
),
f AS (
    SELECT order_id, date_ordered, customer_id, address_id, amount, method_payment, r_paid,
           -- Плаќање при достава: нарачката не е платена додека не се достави → останува 'pending'
           CASE WHEN method_payment = 'cash_on_delivery' AND status IN ('paid', 'shipped') THEN 'pending' ELSE status END AS status,
           status AS logistic_status,                                            -- реална состојба на пратката
           CASE WHEN status IN ('paid', 'shipped', 'delivered') THEN ship_date END AS ship_date,
           CASE WHEN status = 'delivered' THEN least(ship_date + 1 + floor(r_dlv * 4)::int, date '2026-09-30') END AS delivered_date
    FROM s
)
SELECT f.order_id, f.date_ordered, f.customer_id, f.address_id, f.amount, f.method_payment,
       f.status, f.logistic_status, f.ship_date, f.delivered_date,
       CASE WHEN f.status IN ('pending', 'cancelled') THEN NULL
            WHEN f.method_payment IN ('card', 'installments') THEN f.date_ordered + (1 + f.r_paid * 119) * interval '1 minute'
            WHEN f.method_payment = 'bank_transfer'
                 THEN greatest(f.date_ordered + interval '1 hour',
                               least(f.date_ordered + (1 + f.r_paid * 2) * interval '1 day', timestamp '2026-09-30 23:00'))
            ELSE f.delivered_date + (10 + f.r_paid * 8) * interval '1 hour'         -- поузеќе: на денот на доставата
       END AS date_paid
FROM f;
ALTER TABLE seed.stg_orders_final ADD PRIMARY KEY (order_id);
