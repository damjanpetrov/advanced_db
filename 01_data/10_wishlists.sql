-- =====================================================================
--  10 — Листи на желби: 10% купувачи имаат „Default“, 2% и „Подароци“;
--  1–5 производи по листа според популарноста (Парето), секој еднаш.
-- =====================================================================
\echo '== 10_wishlists.sql' `date +%T`
SELECT setseed(0.1010);
SELECT count(*) AS n_products FROM seed.product_rank \gset
SELECT count(*) AS n_early FROM seed.product_rank_early \gset

INSERT INTO wishlist (name, created_at, customer_id)
SELECT 'Default', c.created_at + random() * (timestamp '2026-09-30' - c.created_at), c.customer_id
FROM (SELECT customer_id, created_at, random() AS r FROM customer) c WHERE c.r < 0.10;

INSERT INTO wishlist (name, created_at, customer_id)
SELECT 'Подароци', w.created_at + random() * (timestamp '2026-09-30' - w.created_at), w.customer_id
FROM (SELECT customer_id, created_at, random() AS r FROM wishlist) w WHERE w.r < 0.20;

INSERT INTO wishlist_items (added_at, wishlist_id, product_id)
SELECT DISTINCT ON (x.wishlist_id, x.product_id) x.added_at, x.wishlist_id, x.product_id
FROM (
    SELECT w.wishlist_id, a.added_at,
           CASE WHEN pr.created_at <= a.added_at THEN pr.product_id ELSE pe.product_id END AS product_id
    FROM (SELECT wishlist_id, created_at, 1 + floor(random() * 5)::int AS n FROM wishlist) w
    CROSS JOIN LATERAL generate_series(1, w.n) k
    CROSS JOIN LATERAL (SELECT w.created_at + random() * (timestamp '2026-09-30' - w.created_at) AS added_at,
                               1 + floor(:n_products * power(random(), 5.5))::int + 0 * k AS rnk) a
    JOIN seed.product_rank pr       ON pr.rank = a.rnk
    JOIN seed.product_rank_early pe ON pe.rank = 1 + (a.rnk - 1) % :n_early
) x
ORDER BY x.wishlist_id, x.product_id, x.added_at;
