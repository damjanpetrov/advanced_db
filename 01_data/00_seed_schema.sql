-- =====================================================================
--  00 — Помошна шема `seed`: lookup табели, „пикери“ и календар
--  Помошните табели не се дел од моделот на апликацијата. Се користат само
--  за генерирање и се во посебна шема, за да не се мешаат со `public`.
--  \copy патеките се релативни на папката од која се пушта psql (коренот на проектот).
-- =====================================================================
\echo '== 00_seed_schema.sql' `date +%T`

DROP SCHEMA IF EXISTS seed CASCADE;
CREATE SCHEMA seed;

-- ---------------------------------------------------------------------
-- 1. Lookup табели од CSV (техника од аудиториска вежба 2: COPY во помошна табела)
--    grp = група/држава (MK = Македонци, MKA = Албанци во МК, AL = Албанија, DE, IT, ...).
--    CSV-ата се генерирани со tools/build_lookup_csv.py (рачни листи + Faker).
-- ---------------------------------------------------------------------
CREATE TABLE seed.first_names (grp text, gender char(1), name text, name_lat text);
CREATE TABLE seed.surnames    (grp text, gender char(1), surname text, surname_lat text);  -- gender A = исто за двата пола
CREATE TABLE seed.cities      (grp text, city text, weight int);
CREATE TABLE seed.streets     (grp text, street text);

\copy seed.first_names FROM '01_data/csv/first_names.csv' CSV HEADER
\copy seed.surnames    FROM '01_data/csv/surnames.csv'    CSV HEADER
\copy seed.cities      FROM '01_data/csv/cities.csv'      CSV HEADER
\copy seed.streets     FROM '01_data/csv/streets.csv'     CSV HEADER

-- Групи: удел во купувачите, држава, телефонски простор (мобилни броеви)
CREATE TABLE seed.groups (grp text PRIMARY KEY, country text, share numeric, addr_grp text,
                          cc text, mob_prefix text, mob_digits int);
INSERT INTO seed.groups VALUES
 ('MK','North Macedonia',18.0,'MK','389','7',7),  ('MKA','North Macedonia',0.5,'MK','389','7',7),
 ('AL','Albania',0.2,'AL','355','6',8),           ('BG','Bulgaria',5.0,'BG','359','8',8),
 ('GR','Greece',8.0,'GR','30','69',8),            ('HR','Croatia',6.0,'HR','385','9',8),
 ('SI','Slovenia',2.0,'SI','386','4',7),          ('RO','Romania',1.0,'RO','40','7',8),
 ('TR','Turkey',2.3,'TR','90','5',9),             ('DE','Germany',14.0,'DE','49','15',9),
 ('AT','Austria',7.0,'AT','43','66',8),           ('IT','Italy',9.0,'IT','39','3',9),
 ('NL','Netherlands',7.0,'NL','31','6',8),        ('ES','Spain',9.0,'ES','34','6',8),
 ('PL','Poland',3.0,'PL','48','5',8),             ('US','United States',8.0,'US','1','2',9);

-- ---------------------------------------------------------------------
-- 2. „Пикери“ за градови и улици по држава: град со тежина (пр. Скопје 520 пати),
--    густ id 1..N → избор со id = 1 + floor(random() * N), без ORDER BY random().
-- ---------------------------------------------------------------------
CREATE TABLE seed.pick_city AS
SELECT grp, row_number() OVER (PARTITION BY grp ORDER BY city, g) AS id, city
FROM seed.cities, generate_series(1, weight) g;
CREATE TABLE seed.pick_street AS
SELECT grp, row_number() OVER (PARTITION BY grp ORDER BY street) AS id, street
FROM (SELECT DISTINCT grp, street FROM seed.streets) s;
CREATE TABLE seed.grp_size AS
SELECT g.grp,
       (SELECT count(*) FROM seed.pick_city c WHERE c.grp = g.grp)   AS n_city,
       (SELECT count(*) FROM seed.pick_street s WHERE s.grp = g.grp) AS n_street
FROM (SELECT DISTINCT addr_grp AS grp FROM seed.groups) g;

CREATE TABLE seed.email_domains (id int PRIMARY KEY, domain text);
INSERT INTO seed.email_domains VALUES
 (1,'gmail.com'),(2,'gmail.com'),(3,'gmail.com'),(4,'gmail.com'),(5,'gmail.com'),
 (6,'yahoo.com'),(7,'hotmail.com'),(8,'outlook.com'),(9,'icloud.com'),(10,'live.com');

-- ---------------------------------------------------------------------
-- 3. Базен на луѓе: УНИКАТНИ комбинации име + презиме (за купувачи и вработени).
--    * комбинации само во иста група (германско име со германско презиме, ...)
--    * уникатноста е по латинската форма (name_lat, surname_lat) → уникатен е и email-от
--    * од секоја група се зема квота според уделот; 150 македонски се вработени
-- ---------------------------------------------------------------------
SELECT (1000000 * :scale)::int AS n_customers \gset

-- квота и капацитет (број на можни комбинации) по група
CREATE TABLE seed.quota AS
WITH fn AS (SELECT grp, gender, count(*) AS n FROM seed.first_names GROUP BY 1, 2),
     sn AS (SELECT grp, gender, count(*) AS n FROM seed.surnames GROUP BY 1, 2),
     cap AS (SELECT fn.grp, sum(fn.n * (SELECT coalesce(sum(sn.n), 0) FROM sn
                                         WHERE sn.grp = fn.grp AND sn.gender IN (fn.gender, 'A'))) AS capacity
             FROM fn GROUP BY fn.grp)
SELECT g.grp,
       round(:n_customers * g.share / 100.0)::int + CASE WHEN g.grp = 'MK' THEN 150 ELSE 0 END AS quota,
       cap.capacity
FROM seed.groups g JOIN cap USING (grp);
ALTER TABLE seed.quota ADD COLUMN p float;
UPDATE seed.quota SET p = least(1.0, 2.5 * quota / capacity);   -- колкав дел од комбинациите да се земе во примерокот

CREATE TABLE seed.person_pool AS
WITH combos AS (   -- примерок од сите комбинации име × презиме во групата (доволно поголем од квотата)
    -- random() е во листата на подпрашањето: така се пресметува за СЕКОЈ ред.
    -- (Во WHERE, „random() < q.p“ планерот би го пресметал само еднаш по ред од quota.)
    SELECT c.grp, c.gender, c.name, c.surname, c.name_lat, c.surname_lat
    FROM (SELECT f.grp, f.gender, f.name, s.surname, f.name_lat, s.surname_lat, random() AS r
          FROM seed.first_names f
          JOIN seed.surnames s ON s.grp = f.grp AND s.gender IN (f.gender, 'A')) c
    JOIN seed.quota q ON q.grp = c.grp
    WHERE c.r < q.p
),
dedup AS (    -- иста латинска комбинација (пр. „Иван Петров“ во MK и BG) само еднаш
    SELECT DISTINCT ON (name_lat, surname_lat) * FROM combos ORDER BY name_lat, surname_lat, random()
),
ranked AS (
    SELECT d.*, row_number() OVER (PARTITION BY grp ORDER BY random()) AS rn FROM dedup d
)
SELECT r.grp, r.gender, r.name, r.surname, r.name_lat, r.surname_lat,
       (r.grp = 'MK' AND r.rn <= 150) AS is_employee,
       CASE WHEN r.grp = 'MK' AND r.rn <= 150 THEN r.rn END AS employee_id
FROM ranked r JOIN seed.quota q USING (grp)
WHERE r.rn <= q.quota;

-- Мобилен број: уникатен по конструкција. За индекс k (уникатен во рамки на државата)
-- (k × 7.654.321 + 3.141.592) mod 10^d е биекција (множителот е заемно прост со 10^d и со 7·10^6)
-- → различен k дава различен број, а броевите не изгледаат последователно (поместувањето зависи од државата).
-- МК: 07X XXX XXX или +389 7X XXX XXX; другите држави: +кодна_земја + мобилен префикс + d цифри (E.164).
CREATE FUNCTION seed.mobile(p_grp text, k bigint, local_fmt boolean) RETURNS text
LANGUAGE sql STABLE AS $f$
    SELECT CASE WHEN g.addr_grp = 'MK' THEN
                CASE WHEN local_fmt THEN '07' ELSE '+3897' END
                || (ARRAY['0','1','2','5','6','7','8'])[1 + ((k * 7654321 + 3141592) % 7000000) % 7]
                || lpad((((k * 7654321 + 3141592) % 7000000) / 7)::text, 6, '0')
           ELSE '+' || g.cc || g.mob_prefix
                || lpad(((k * 7654321 + 3141592 + abs(hashtext(g.grp)) % 10000000) % power(10, g.mob_digits)::bigint)::text, g.mob_digits, '0')
           END
    FROM seed.groups g WHERE g.grp = p_grp
$f$;

-- customer_id = случаен редослед (за да не се групирани по држава)
ALTER TABLE seed.person_pool ADD COLUMN customer_id int;
UPDATE seed.person_pool p SET customer_id = x.id
FROM (SELECT ctid AS t, row_number() OVER (ORDER BY random()) AS id FROM seed.person_pool WHERE NOT is_employee) x
WHERE p.ctid = x.t;

-- ---------------------------------------------------------------------
-- 3. Мали lookup табели (INSERT)
-- ---------------------------------------------------------------------
CREATE TABLE seed.banks (id int PRIMARY KEY, bank text);
INSERT INTO seed.banks VALUES
 (1,'Комерцијална банка'),(2,'Стопанска банка'),(3,'НЛБ Банка'),(4,'Халк Банка'),
 (5,'Шпаркасе Банка'),(6,'ПроКредит Банка'),(7,'УНИ Банка'),(8,'Силк Роуд Банка');

CREATE TABLE seed.carriers (id int PRIMARY KEY, carrier text, prefix text);
INSERT INTO seed.carriers VALUES
 (1,'Пошта на Северна Македонија','PMK'),(2,'GO Express','GOE'),(3,'Delco','DLC'),(4,'DHL Express','DHL');

CREATE TABLE seed.return_reasons (id int PRIMARY KEY, reason text);
INSERT INTO seed.return_reasons VALUES
 (1,'Производот не работи'),(2,'Оштетен при достава'),(3,'Не одговара на описот'),
 (4,'Погрешен производ испратен'),(5,'Се премислив'),(6,'Најдов поевтино'),
 (7,'Проблем со компатибилност'),(8,'Дефект по неколку дена користење');

CREATE TABLE seed.complaints (id int PRIMARY KEY, complaint text);
INSERT INTO seed.complaints VALUES
 (1,'Нарачката доцни повеќе од очекуваното.'),(2,'Не можам да го следам пакетот.'),
 (3,'Добив погрешна боја на производот.'),(4,'Фактурата не е точна.'),
 (5,'Плаќањето со картичка не помина, а парите се резервирани.'),
 (6,'Курирот не ме контактираше пред доставата.'),(7,'Прашање за гаранција на уредот.'),
 (8,'Производот пристигна без полнач.'),(9,'Барам замена наместо враќање на пари.'),
 (10,'Не можам да се најавам на профилот.');

CREATE TABLE seed.review_comments (rating int, id int, comment text, PRIMARY KEY (rating, id));
INSERT INTO seed.review_comments VALUES
 (5,1,'Одличен производ, препорачувам!'),(5,2,'Брза достава, сè е како во описот.'),
 (5,3,'Најдобра купувачка оваа година.'),(5,4,'Супер квалитет за таа цена.'),
 (4,1,'Многу добро, мала забелешка за пакувањето.'),(4,2,'Задоволен сум, доставата малку доцнеше.'),
 (4,3,'Добар однос цена–квалитет.'),(4,4,'Работи без проблем.'),
 (3,1,'Просечно, очекував повеќе.'),(3,2,'Во ред е, ништо посебно.'),
 (3,3,'Работи, но е гласен.'),(3,4,'Упатството е само на англиски.'),
 (2,1,'Квалитетот не е како на сликите.'),(2,2,'Батеријата трае кратко.'),
 (2,3,'Се загрева премногу.'),(2,4,'Не би купил повторно.'),
 (1,1,'Пристигна неисправен.'),(1,2,'Многу лошо искуство.'),
 (1,3,'Престана да работи по една недела.'),(1,4,'Не препорачувам.');

-- ---------------------------------------------------------------------
-- 4. Календар: тежина за секој ден 2021-01-01 … 2026-09-30
--    тренд (раст ~25%/год) × месец × Black Friday × ден во неделата
-- ---------------------------------------------------------------------
CREATE TABLE seed.calendar AS
WITH d AS (
    SELECT day::date AS day FROM generate_series(date '2021-01-01', date '2026-09-30', interval '1 day') day
), bf AS (  -- Black Friday = денот по четвртиот четврток во ноември
    SELECT y, (make_date(y, 11, 1) + ((4 - extract(isodow FROM make_date(y, 11, 1))::int + 7) % 7) + 22) AS bf_day
    FROM generate_series(2021, 2026) y
)
SELECT d.day,
       power(1.25, (d.day - date '2021-01-01') / 365.25)                          -- тренд
     * CASE extract(month FROM d.day)::int
           WHEN 1 THEN 0.80 WHEN 2 THEN 0.85 WHEN 8 THEN 0.85 WHEN 9 THEN 1.15
           WHEN 11 THEN 1.60 WHEN 12 THEN CASE WHEN extract(day FROM d.day) <= 20 THEN 1.50 ELSE 0.90 END
           ELSE 1.00 END                                                          -- сезона
     * CASE WHEN d.day BETWEEN bf.bf_day - 3 AND bf.bf_day + 3 THEN 3.0 ELSE 1.0 END -- Black Friday
     * CASE extract(isodow FROM d.day)::int WHEN 1 THEN 1.10 WHEN 6 THEN 0.90 ELSE 1.00 END
       AS weight
FROM d JOIN bf ON bf.y = extract(year FROM d.day);

-- Час во денот: врв навечер (19–22), минимум ноќе
CREATE TABLE seed.pick_hour AS
SELECT row_number() OVER (ORDER BY h, g) AS id, h AS hour
FROM (VALUES (0,3),(1,2),(2,1),(3,1),(4,1),(5,1),(6,2),(7,3),(8,5),(9,6),(10,7),(11,7),
             (12,8),(13,8),(14,7),(15,7),(16,7),(17,8),(18,9),(19,11),(20,12),(21,11),(22,8),(23,5)) v(h, w),
     generate_series(1, w) g;

ANALYZE seed.person_pool, seed.pick_city, seed.pick_street, seed.calendar, seed.pick_hour;
