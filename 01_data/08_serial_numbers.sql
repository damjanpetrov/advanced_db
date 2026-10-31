-- =====================================================================
--  08 — Сериски броеви: секое парче има свој ред
--  * продадени/резервирани: за секоја ставка (што не е откажана) по `quantity` редови
--  * залиха: за секој активен производ 0–40 парчиња in_stock, ~1% defective
--  serial_code = префикс на бренд + година на прием + serial_number_id → уникатен по конструкција
-- =====================================================================
\echo '== 08_serial_numbers.sql' `date +%T`
SELECT setseed(0.808);

CREATE OR REPLACE PROCEDURE seed.load_serials()
LANGUAGE plpgsql AS $$
DECLARE y int; base bigint; n bigint;
BEGIN
    FOR y IN 2021..2026 LOOP
        SELECT coalesce(max(serial_number_id), 0) INTO base FROM serial_number;
        INSERT INTO serial_number (serial_number_id, serial_code, status, received_at, product_id, warehouse_id, order_item_id)
        SELECT base + row_number() OVER (ORDER BY x.order_item_id, x.g),
               upper(left(regexp_replace(x.manufacturer, '[^A-Za-z]', '', 'g'), 3)) || '-' || to_char(x.received_at, 'YYYY') || '-'
                   || lpad((base + row_number() OVER (ORDER BY x.order_item_id, x.g))::text, 10, '0'),
               x.status, x.received_at, x.product_id, x.warehouse_id, x.order_item_id
        FROM (
            SELECT oi.order_item_id, g, oi.product_id, p.manufacturer,
                   CASE WHEN oi.status IN ('shipped', 'delivered') THEN 'sold' ELSE 'reserved' END AS status,
                   -- прием во магацин 1–60 дена пред нарачката, но не пред излегувањето на производот
                   greatest(o.date_ordered - (1 + random() * 59) * interval '1 day', p.created_at) AS received_at,
                   CASE WHEN oi.r < 0.45 THEN 1 WHEN oi.r < 0.65 THEN 2 WHEN oi.r < 0.77 THEN 3
                        WHEN oi.r < 0.87 THEN 4 WHEN oi.r < 0.95 THEN 5 ELSE 6 END AS warehouse_id
            FROM (SELECT order_item.*, random() AS r FROM order_item) oi
            JOIN orders o  ON o.order_id = oi.order_id
            JOIN product p ON p.product_id = oi.product_id
            CROSS JOIN LATERAL generate_series(1, oi.quantity) g
            WHERE oi.status <> 'cancelled'
              AND o.date_ordered >= make_timestamp(y, 1, 1, 0, 0, 0) AND o.date_ordered < make_timestamp(y + 1, 1, 1, 0, 0, 0)
        ) x;
        GET DIAGNOSTICS n = ROW_COUNT;
        COMMIT;
        RAISE NOTICE '% : serial_number %  (%)', y, n, clock_timestamp()::time(0);
    END LOOP;
END $$;

CALL seed.load_serials();

-- Тековна залиха (без order_item): 0–40 парчиња по активен производ
SELECT coalesce(max(serial_number_id), 0) AS base FROM serial_number \gset
INSERT INTO serial_number (serial_number_id, serial_code, status, received_at, product_id, warehouse_id)
SELECT :base + row_number() OVER (ORDER BY p.product_id, g),
       upper(left(regexp_replace(p.manufacturer, '[^A-Za-z]', '', 'g'), 3)) || '-' || to_char(rcv, 'YYYY') || '-'
           || lpad((:base + row_number() OVER (ORDER BY p.product_id, g))::text, 10, '0'),
       CASE WHEN random() < 0.01 THEN 'defective' ELSE 'in_stock' END,
       rcv, p.product_id, 1 + floor(random() * 6)::int
FROM product p
CROSS JOIN LATERAL generate_series(1, floor(random() * 41 + 0 * p.product_id)::int) g  -- референцата на p го прави random() различен по производ
CROSS JOIN LATERAL (SELECT greatest(timestamp '2026-09-30' - random() * interval '90 days', p.created_at) + 0 * g * interval '1 s' AS rcv) r
WHERE p.is_active;
