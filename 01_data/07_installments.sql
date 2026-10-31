-- =====================================================================
--  07 — Рати за нарачките платени на рати (3 / 6 / 12 рати)
--  Збирот на ратите е точно износот на нарачката (последната го зема остатокот).
--  Минатите рати: 96% платени до рокот, 2% задоцнети, 2% неплатени (за поглед за доспеани рати).
-- =====================================================================
\echo '== 07_installments.sql' `date +%T`
SELECT setseed(0.707);

INSERT INTO installments (installment_no, amount, due_date, paid_at, bank, order_id)
SELECT k,
       CASE WHEN k < o.n THEN round(o.amount / o.n, 2) ELSE o.amount - round(o.amount / o.n, 2) * (o.n - 1) END,
       due,
       CASE WHEN due > date '2026-09-30' THEN NULL
            WHEN r < 0.96 THEN due - floor(random() * 6)::int + (8 + random() * 12) * interval '1 hour'
            WHEN r < 0.98 THEN least(due + (1 + floor(random() * 20))::int, date '2026-09-30') + interval '12 hours'
            ELSE NULL END,
       o.bank, o.order_id
FROM (
    SELECT order_id, amount, date_paid,
           CASE WHEN random() < 0.4 THEN 3 WHEN random() < 0.67 THEN 6 ELSE 12 END AS n,
           (SELECT bank FROM seed.banks WHERE id = 1 + (order_id % 8)::int) AS bank
    FROM orders
    WHERE method_payment = 'installments' AND date_paid IS NOT NULL
) o
CROSS JOIN LATERAL generate_series(1, o.n) k
CROSS JOIN LATERAL (SELECT (o.date_paid::date + make_interval(months => k))::date AS due, random() AS r) d;
