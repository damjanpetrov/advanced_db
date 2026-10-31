-- =====================================================================
--  09 — Постпродажба: рецензии, враќања, пријави до поддршка
-- =====================================================================
\echo '== 09_after_sales.sql' `date +%T`
SELECT setseed(0.909);

-- Рецензии: ~5% од доставените ставки, 2–30 дена по доставата.
-- Оценки: 5 (45%), 4 (28%), 3 (12%), 2 (6%), 1 (9%); коментар во 60% случаи.
INSERT INTO review (rating, date, comment, order_item_id)
SELECT x.rating, x.rdate, CASE WHEN x.r_c < 0.6 THEN rc.comment END, x.order_item_id
FROM (
    SELECT oi.order_item_id,
           CASE WHEN r < 0.45 THEN 5 WHEN r < 0.73 THEN 4 WHEN r < 0.85 THEN 3 WHEN r < 0.91 THEN 2 ELSE 1 END AS rating,
           s.delivered_date + (2 + random() * 28) * interval '1 day' AS rdate,
           random() AS r_c, 1 + floor(random() * 4)::int AS c_id
    FROM (SELECT order_item_id, order_id, random() AS r, random() AS r_pick FROM order_item WHERE status = 'delivered') oi
    JOIN shipping s ON s.shipping_id = oi.order_id
    WHERE oi.r_pick < 0.05
) x
JOIN seed.review_comments rc ON rc.rating = x.rating AND rc.id = x.c_id
WHERE x.rdate <= timestamp '2026-09-30 23:59';

-- Враќања: ~1% од доставените ставки, до 14 дена по доставата
INSERT INTO returns (date, reason, quantity, status, resolved_at, order_item_id, employee_id)
SELECT x.rdate, rr.reason, 1, x.status,
       CASE WHEN x.status IN ('completed', 'rejected') THEN least(x.rdate + (1 + floor(random() * 10))::int, date '2026-09-30') + interval '14 hours' END,
       x.order_item_id,
       CASE WHEN x.status <> 'requested' THEN 116 + floor(random() * 15)::int END   -- вработени со улога „Обработка враќања“
FROM (
    SELECT oi.order_item_id, d.rdate, oi.r_reason,
           CASE WHEN date '2026-09-30' - d.rdate > 30 THEN CASE WHEN oi.r_st < 0.75 THEN 'completed' ELSE 'rejected' END
                WHEN date '2026-09-30' - d.rdate >= 7 THEN CASE WHEN oi.r_st < 0.40 THEN 'approved' WHEN oi.r_st < 0.80 THEN 'completed' ELSE 'rejected' END
                ELSE CASE WHEN oi.r_st < 0.70 THEN 'requested' ELSE 'approved' END END AS status
    FROM (SELECT order_item_id, order_id, random() AS r_pick, random() AS r_st, random() AS r_reason, random() AS r_d
          FROM order_item WHERE status = 'delivered') oi
    JOIN shipping s ON s.shipping_id = oi.order_id
    CROSS JOIN LATERAL (SELECT (s.delivered_date + floor(oi.r_d * 15)::int)::date AS rdate) d
    WHERE oi.r_pick < 0.01 AND d.rdate <= date '2026-09-30'
) x
JOIN seed.return_reasons rr ON rr.id = 1 + floor(x.r_reason * 8)::int;

-- Вратените уреди (завршено враќање): по еден сериски број на ставката станува 'returned'
UPDATE serial_number sn SET status = 'returned'
FROM (
    SELECT DISTINCT ON (s.order_item_id) s.serial_number_id
    FROM serial_number s
    JOIN returns r ON r.order_item_id = s.order_item_id AND r.status = 'completed'
    ORDER BY s.order_item_id, s.serial_number_id
) x
WHERE sn.serial_number_id = x.serial_number_id;

-- Пријави поврзани со нарачка (~0,3% од нарачките), 1–20 дена по нарачката
INSERT INTO customer_support_report (complaint, date, issue_solved, resolved_at, employee_id, customer_id, order_id)
SELECT c.complaint, x.rdate, x.solved,
       CASE WHEN x.solved THEN x.rdate + (1 + random() * 167) * interval '1 hour' END,
       86 + floor(random() * 30)::int,                                     -- вработени со улога „Корисничка поддршка“
       x.customer_id, x.order_id
FROM (
    SELECT o.order_id, o.customer_id, d.rdate,
           (timestamp '2026-09-30' - d.rdate > interval '7 days' AND o.r_s < 0.85) AS solved, o.r_c
    FROM (SELECT order_id, customer_id, date_ordered, random() AS r_pick, random() AS r_s, random() AS r_c, random() AS r_d
          FROM orders) o
    CROSS JOIN LATERAL (SELECT o.date_ordered + (1 + o.r_d * 19) * interval '1 day' AS rdate) d
    WHERE o.r_pick < 0.003 AND d.rdate < timestamp '2026-09-30 23:00'
) x
JOIN seed.complaints c ON c.id = 1 + floor(x.r_c * 10)::int;

-- Општи пријави без нарачка (~2% од купувачите)
INSERT INTO customer_support_report (complaint, date, issue_solved, resolved_at, employee_id, customer_id)
SELECT c.complaint, x.rdate, x.solved,
       CASE WHEN x.solved THEN x.rdate + (1 + random() * 71) * interval '1 hour' END,
       86 + floor(random() * 30)::int, x.customer_id
FROM (
    SELECT cu.customer_id, d.rdate, (timestamp '2026-09-30' - d.rdate > interval '7 days' AND cu.r_s < 0.85) AS solved, cu.r_c
    FROM (SELECT customer_id, created_at, random() AS r_pick, random() AS r_s, random() AS r_c, random() AS r_d FROM customer) cu
    CROSS JOIN LATERAL (SELECT cu.created_at + cu.r_d * (timestamp '2026-09-30' - cu.created_at) AS rdate) d
    WHERE cu.r_pick < 0.02
) x
JOIN seed.complaints c ON c.id = 1 + floor(x.r_c * 10)::int;
