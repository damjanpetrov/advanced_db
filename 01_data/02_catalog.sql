-- =====================================================================
--  02 — Каталог: магацини, категории, добавувачи, производи, атрибути
--  Сите цени се во денари (МКД).
-- =====================================================================
\echo '== 02_catalog.sql' `date +%T`
SELECT setseed(0.202);

INSERT INTO warehouse (warehouse_id, name, city, number, street) VALUES
 (1,'Скопје 1 — централен','Скопје','12','Индустриска'),(2,'Скопје 2','Скопје','45','Бутелски венец'),
 (3,'Битола','Битола','3','Индустриска зона'),(4,'Куманово','Куманово','8','Доне Божинов'),
 (5,'Тетово','Тетово','21','Илинденска'),(6,'Охрид','Охрид','5','Туристичка');

-- Категории: 8 главни, 26 подкатегории
INSERT INTO category (category_id, name, description, parent_category_id) VALUES
 (1,'Лаптопи',NULL,NULL),(2,'Мобилни телефони',NULL,NULL),(3,'Компјутерски компоненти',NULL,NULL),
 (4,'Монитори',NULL,NULL),(5,'Периферија',NULL,NULL),(6,'Мрежна опрема',NULL,NULL),
 (7,'ТВ и аудио',NULL,NULL),(8,'Додатоци',NULL,NULL),
 (11,'Gaming лаптопи',NULL,1),(12,'Бизнис лаптопи',NULL,1),(13,'Ултрабуци',NULL,1),
 (21,'Паметни телефони',NULL,2),(22,'Маски и заштита',NULL,2),
 (31,'Процесори',NULL,3),(32,'Графички картички',NULL,3),(33,'Матични плочи',NULL,3),
 (34,'RAM меморија',NULL,3),(35,'SSD дискови',NULL,3),(36,'Напојувања',NULL,3),
 (41,'Gaming монитори',NULL,4),(42,'Канцелариски монитори',NULL,4),
 (51,'Тастатури',NULL,5),(52,'Глувчиња',NULL,5),(53,'Слушалки',NULL,5),(54,'Веб камери',NULL,5),
 (61,'Рутери',NULL,6),(62,'Свичеви',NULL,6),
 (71,'Телевизори',NULL,7),(72,'Звучници',NULL,7),
 (81,'Кабли и адаптери',NULL,8),(82,'Полначи',NULL,8),(83,'Чанти и ранци',NULL,8),
 (84,'Мемориски картички',NULL,8),(85,'Power bank',NULL,8);

-- 40 дистрибутери
INSERT INTO supplier (supplier_id, name, company, email, phone)
SELECT i, 'Добавувач ' || i,
       (ARRAY['Дистрибуција','Трејд','Компјутери','Електроникс','Импекс'])[1 + i % 5] || ' ' ||
       (ARRAY['Алфа','Бета','Север','Вардар','Пелагонија','Балкан','Нова','Глобал'])[1 + i % 8] || ' ДООЕЛ',
       'sales' || i || '@supplier' || i || '.mk',
       '+3892' || lpad((3000000 + i * 7919 % 999999)::text, 7, '0')
FROM generate_series(1, 40) i;

-- Шаблони: подкатегорија × бренд × линија, опсег на цена и опции за спецификација
CREATE TABLE seed.product_templates (
    id serial PRIMARY KEY, category_id int, brand text, line text,
    price_min numeric, price_max numeric, specs text[]
);
INSERT INTO seed.product_templates (category_id, brand, line, price_min, price_max, specs) VALUES
 (11,'ASUS','ROG Strix',75000,160000,'{"16GB/512GB RTX 4060","16GB/1TB RTX 4070","32GB/1TB RTX 4080"}'),
 (11,'Lenovo','Legion 5',70000,130000,'{"16GB/512GB RTX 4060","32GB/1TB RTX 4070"}'),
 (11,'MSI','Katana',55000,95000,'{"16GB/512GB RTX 4050","16GB/1TB RTX 4060"}'),
 (11,'Acer','Nitro 5',50000,85000,'{"8GB/512GB RTX 3050","16GB/512GB RTX 4050"}'),
 (12,'Lenovo','ThinkPad E14',38000,65000,'{"i5/8GB/256GB","i5/16GB/512GB","i7/16GB/512GB"}'),
 (12,'HP','ProBook 450',36000,60000,'{"i5/8GB/256GB","i5/16GB/512GB","i7/16GB/1TB"}'),
 (12,'Dell','Latitude 5540',45000,80000,'{"i5/16GB/512GB","i7/16GB/512GB","i7/32GB/1TB"}'),
 (13,'Apple','MacBook Air',65000,110000,'{"M2/8GB/256GB","M3/8GB/256GB","M3/16GB/512GB"}'),
 (13,'ASUS','Zenbook 14',50000,80000,'{"Ultra 5/16GB/512GB","Ultra 7/16GB/1TB"}'),
 (13,'Lenovo','Yoga Slim 7',48000,75000,'{"Ryzen 7/16GB/512GB","Ultra 7/16GB/1TB"}'),
 (21,'Samsung','Galaxy A',12000,28000,'{"4GB/128GB","6GB/128GB","8GB/256GB"}'),
 (21,'Samsung','Galaxy S',45000,85000,'{"8GB/128GB","8GB/256GB","12GB/512GB"}'),
 (21,'Apple','iPhone',45000,95000,'{"128GB","256GB","512GB"}'),
 (21,'Xiaomi','Redmi Note',10000,22000,'{"6GB/128GB","8GB/256GB"}'),
 (21,'Motorola','Moto G',8000,16000,'{"4GB/64GB","4GB/128GB"}'),
 (22,'Spigen','Tough Armor',900,2200,'{"Black","Clear","Navy"}'),
 (22,'Samsung','Silicone Case',1200,2500,'{"Black","White","Lavender"}'),
 (31,'Intel','Core i5',9000,16000,'{"12400F","13400F","14400F"}'),
 (31,'Intel','Core i7',18000,28000,'{"13700K","14700K"}'),
 (31,'AMD','Ryzen 5',7500,15000,'{"5600","7600","7600X"}'),
 (31,'AMD','Ryzen 7',13000,26000,'{"5800X3D","7700X","7800X3D"}'),
 (32,'ASUS','Dual GeForce',18000,40000,'{"RTX 4060 8GB","RTX 4060 Ti 8GB"}'),
 (32,'MSI','Gaming X',35000,95000,'{"RTX 4070 12GB","RTX 4070 Ti 12GB","RTX 4080 16GB"}'),
 (32,'Sapphire','Pulse Radeon',17000,45000,'{"RX 7600 8GB","RX 7700 XT 12GB","RX 7800 XT 16GB"}'),
 (33,'ASUS','TUF Gaming',8000,16000,'{"B650-PLUS","B760-PLUS","Z790-PLUS"}'),
 (33,'MSI','PRO',6000,12000,'{"B650-P","B760-P","H610M"}'),
 (34,'Kingston','FURY Beast',2500,9000,'{"16GB DDR4","32GB DDR4","16GB DDR5","32GB DDR5"}'),
 (34,'Corsair','Vengeance',3000,10000,'{"16GB DDR5","32GB DDR5"}'),
 (35,'Samsung','990 Pro',6000,16000,'{"1TB","2TB"}'),
 (35,'Kingston','NV2',2500,7000,'{"500GB","1TB","2TB"}'),
 (35,'WD','Black SN850X',5500,14000,'{"1TB","2TB"}'),
 (36,'Corsair','RM',5500,10000,'{"650W","750W","850W"}'),
 (36,'be quiet!','Pure Power',4500,8000,'{"600W","750W"}'),
 (41,'Samsung','Odyssey G5',14000,25000,'{"27\" QHD 165Hz","32\" QHD 165Hz"}'),
 (41,'LG','UltraGear',12000,35000,'{"24\" FHD 144Hz","27\" QHD 165Hz","27\" 4K 144Hz"}'),
 (41,'AOC','Gaming',8000,15000,'{"24\" FHD 165Hz","27\" FHD 180Hz"}'),
 (42,'Dell','P Series',9000,18000,'{"24\" FHD","27\" QHD"}'),
 (42,'Philips','V Line',6000,10000,'{"22\" FHD","24\" FHD"}'),
 (51,'Logitech','MX Keys',5500,7500,'{"US","US Mini"}'),
 (51,'Razer','BlackWidow',6000,12000,'{"V4","V4 X"}'),
 (51,'Genius','KB',600,1200,'{"USB","Wireless"}'),
 (52,'Logitech','G Pro',4000,9000,'{"Wired","Wireless","Superlight 2"}'),
 (52,'Logitech','M Series',800,2500,'{"M185","M190","M240"}'),
 (52,'Razer','DeathAdder',2500,6000,'{"Essential","V3"}'),
 (53,'Sony','WH-1000XM',14000,22000,'{"XM4","XM5"}'),
 (53,'HyperX','Cloud',3500,9000,'{"Stinger 2","II","III"}'),
 (53,'JBL','Tune',2000,5000,'{"510BT","520BT","770NC"}'),
 (54,'Logitech','C Series',2500,7000,'{"C270","C920","C922"}'),
 (61,'TP-Link','Archer',1800,9000,'{"C6","AX23","AX55","AX73"}'),
 (61,'ASUS','RT',4000,15000,'{"AX58U","AX86U"}'),
 (62,'TP-Link','TL-SG',900,4000,'{"105","108","116"}'),
 (71,'Samsung','Crystal UHD',22000,45000,'{"43\"","50\"","55\""}'),
 (71,'LG','OLED',60000,140000,'{"48\"","55\"","65\""}'),
 (71,'TCL','QLED',18000,40000,'{"43\"","50\"","55\""}'),
 (72,'JBL','Flip',5000,8000,'{"5","6"}'),
 (72,'Marshall','Emberton',8000,11000,'{"II","III"}'),
 (81,'UGREEN','USB-C кабел',300,1200,'{"1m","2m","3m"}'),
 (81,'Baseus','HDMI кабел',400,1500,'{"1.5m","3m"}'),
 (82,'Anker','Nano',900,3500,'{"20W","30W","65W"}'),
 (82,'Samsung','Super Fast',1200,2800,'{"25W","45W"}'),
 (83,'Targus','City Smart',1800,4500,'{"14\"","15.6\""}'),
 (84,'SanDisk','Extreme microSD',700,4000,'{"64GB","128GB","256GB"}'),
 (85,'Xiaomi','Power Bank',1200,3500,'{"10000mAh","20000mAh"}'),
 (85,'Anker','PowerCore',1500,4500,'{"10000mAh","20000mAh","26800mAh"}');

-- Производи: 5.000. 85% постојат од почетокот на 2021, 15% излегуваат подоцна.
-- Секој производ: шаблон (по ред) + шифра на модел + спецификација.
INSERT INTO product (product_id, name, description, price, is_active, created_at, category_id, manufacturer)
SELECT p.i,
       t.brand || ' ' || t.line || ' ' || upper(substr(md5(p.i::text), 1, 2)) || (100 + p.i % 900) || ' '
           || t.specs[1 + floor(random() * array_length(t.specs, 1))::int],
       'Оригинален производ од ' || t.brand || ', гаранција 24 месеци.',
       round((t.price_min + random() * (t.price_max - t.price_min))::numeric, -1),  -- се пресметува одново во 03
       true,
       CASE WHEN random() < 0.85 THEN timestamp '2020-11-01' + random() * interval '60 days'
            ELSE timestamp '2021-02-01' + random() * (timestamp '2026-06-30' - timestamp '2021-02-01') END,
       t.category_id, t.brand
FROM generate_series(1, 5000) AS p(i)
JOIN seed.product_templates t ON t.id = 1 + p.i % (SELECT count(*) FROM seed.product_templates);

-- ~12% од моделите присутни од почетокот се веќе повлечени (неактивни)
UPDATE product SET is_active = false WHERE created_at < '2021-01-01' AND random() < 0.12;

-- Атрибути: 3–5 по производ според главната категорија
CREATE TABLE seed.attribute_templates (top_category int, name text, vals text[]);
INSERT INTO seed.attribute_templates VALUES
 (1,'Процесор','{"Intel Core i5","Intel Core i7","AMD Ryzen 5","AMD Ryzen 7","Apple M3"}'),
 (1,'RAM','{"8 GB","16 GB","32 GB"}'),(1,'Складирање','{"256 GB SSD","512 GB SSD","1 TB SSD"}'),
 (1,'Екран','{"13.3\"","14\"","15.6\"","16\""}'),(1,'Оперативен систем','{"Windows 11","без ОС","macOS"}'),
 (2,'Меморија','{"64 GB","128 GB","256 GB","512 GB"}'),(2,'RAM','{"4 GB","6 GB","8 GB","12 GB"}'),
 (2,'Екран','{"6.1\"","6.5\"","6.7\""}'),(2,'Боја','{"Црна","Бела","Сина","Зелена"}'),
 (3,'Гаранција','{"24 месеци","36 месеци"}'),(3,'Приклучок','{"AM5","LGA1700","PCIe 4.0","PCIe 5.0"}'),
 (3,'Потрошувачка','{"65 W","105 W","200 W","750 W"}'),
 (4,'Резолуција','{"1920x1080","2560x1440","3840x2160"}'),(4,'Освежување','{"60 Hz","144 Hz","165 Hz","240 Hz"}'),
 (4,'Панел','{"IPS","VA","OLED"}'),
 (5,'Поврзување','{"USB","Bluetooth","2.4 GHz"}'),(5,'Боја','{"Црна","Бела"}'),(5,'Гаранција','{"24 месеци"}'),
 (6,'Стандард','{"Wi-Fi 5","Wi-Fi 6","Wi-Fi 6E"}'),(6,'Порти','{"4","5","8","16"}'),
 (7,'Големина','{"43\"","50\"","55\"","65\""}'),(7,'Резолуција','{"4K UHD","Full HD"}'),(7,'Smart','{"Да","Не"}'),
 (8,'Боја','{"Црна","Бела","Сива"}'),(8,'Гаранција','{"12 месеци","24 месеци"}');

INSERT INTO product_attribute (name, value, product_id)
SELECT a.name, a.vals[1 + floor(random() * array_length(a.vals, 1))::int], p.product_id
FROM product p
JOIN category c ON c.category_id = p.category_id
JOIN seed.attribute_templates a ON a.top_category = c.parent_category_id;

-- 1–2 добавувачи по производ, набавна цена 70–88% од продажната
INSERT INTO product_supplier (product_id, supplier_id, purchase_price)
SELECT p.product_id, s.supplier_id, round((p.price * (0.70 + random() * 0.18))::numeric, 2)
FROM product p
CROSS JOIN LATERAL (
    SELECT DISTINCT 1 + ((p.product_id * 7 + k * 13) % 40) AS supplier_id
    FROM generate_series(1, CASE WHEN p.product_id % 3 = 0 THEN 2 ELSE 1 END) k
) s;

-- Популарност: случајна пермутација ранг → производ (за Парето распределба во нарачките).
-- fallback_rank: само производи што постојат од почетокот (за нарачки пред излегувањето на нов производ).
CREATE TABLE seed.product_rank AS
SELECT row_number() OVER (ORDER BY random()) AS rank, product_id, created_at
FROM product;
CREATE TABLE seed.product_rank_early AS
SELECT row_number() OVER (ORDER BY random()) AS rank, product_id
FROM product WHERE created_at < '2021-01-01';
ALTER TABLE seed.product_rank ADD PRIMARY KEY (rank);
ALTER TABLE seed.product_rank_early ADD PRIMARY KEY (rank);
ANALYZE seed.product_rank, seed.product_rank_early;
