-- =====================================================================
--  06 — Вметнување во shipping, orders, order_item од staging
--  По години (2021 … 2026), со COMMIT по секоја година: напредокот се гледа
--  во логот, а прекин не остава половина табела без поврзани редици.
--  Врски по конструкција: shipping_id = order_id.
-- =====================================================================
\echo '== 06_orders_load.sql' `date +%T`

CREATE OR REPLACE PROCEDURE seed.load_orders()
LANGUAGE plpgsql AS $$
DECLARE
    y int; n_s bigint; n_o bigint; n_i bigint;
BEGIN
    FOR y IN 2021..2026 LOOP
        -- пратки: за нарачки што се подготвуваат, во транспорт или доставени
        INSERT INTO shipping (shipping_id, date, delivered_date, status, carrier, tracking_number)
        SELECT f.order_id, f.ship_date, f.delivered_date,
               CASE f.logistic_status WHEN 'delivered' THEN 'delivered' WHEN 'shipped' THEN 'in_transit' ELSE 'preparing' END,
               c.carrier, c.prefix || lpad(f.order_id::text, 10, '0')
        FROM seed.stg_orders_final f
        JOIN seed.carriers c ON c.id = CASE WHEN f.order_id % 100 < 45 THEN 1 WHEN f.order_id % 100 < 75 THEN 2
                                            WHEN f.order_id % 100 < 92 THEN 3 ELSE 4 END
        WHERE f.ship_date IS NOT NULL
          AND f.date_ordered >= make_timestamp(y, 1, 1, 0, 0, 0) AND f.date_ordered < make_timestamp(y + 1, 1, 1, 0, 0, 0);
        GET DIAGNOSTICS n_s = ROW_COUNT;

        INSERT INTO orders (order_id, date_ordered, status, date_paid, amount, method_payment, customer_id, address_id, shipping_id)
        SELECT f.order_id, f.date_ordered, f.status, f.date_paid, f.amount, f.method_payment, f.customer_id, f.address_id,
               CASE WHEN f.ship_date IS NOT NULL THEN f.order_id END
        FROM seed.stg_orders_final f
        WHERE f.date_ordered >= make_timestamp(y, 1, 1, 0, 0, 0) AND f.date_ordered < make_timestamp(y + 1, 1, 1, 0, 0, 0);
        GET DIAGNOSTICS n_o = ROW_COUNT;

        INSERT INTO order_item (order_item_id, status, order_id, product_id, quantity, unit_price)
        SELECT i.order_item_id, i.status, i.order_id, i.product_id, i.quantity, i.unit_price
        FROM seed.stg_items i
        WHERE i.date_ordered >= make_timestamp(y, 1, 1, 0, 0, 0) AND i.date_ordered < make_timestamp(y + 1, 1, 1, 0, 0, 0);
        GET DIAGNOSTICS n_i = ROW_COUNT;

        COMMIT;
        RAISE NOTICE '% : shipping %, orders %, order_item %  (%)', y, n_s, n_o, n_i, clock_timestamp()::time(0);
    END LOOP;
END $$;

CALL seed.load_orders();
