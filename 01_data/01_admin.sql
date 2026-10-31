-- =====================================================================
--  01 — Администрација: улоги, дозволи, вработени (мали табели, INSERT)
-- =====================================================================
\echo '== 01_admin.sql' `date +%T`
SELECT setseed(0.101);

INSERT INTO role (role_id, role) VALUES
 (1,'Администратор'),(2,'Менаџер'),(3,'Магационер'),(4,'Оператор нарачки'),
 (5,'Корисничка поддршка'),(6,'Обработка враќања'),(7,'Финансии'),(8,'Маркетинг');

INSERT INTO permission (permission_id, name, description) VALUES
 (1,'product.view','Преглед на каталог'),(2,'product.edit','Измена на производи и цени'),
 (3,'promotion.manage','Креирање и измена на акции'),(4,'stock.view','Преглед на залиха'),
 (5,'stock.receive','Прием на стока и сериски броеви'),(6,'stock.move','Пренос меѓу магацини'),
 (7,'order.view','Преглед на нарачки'),(8,'order.edit','Измена на нарачка'),
 (9,'order.cancel','Откажување нарачка'),(10,'order.refund','Враќање пари'),
 (11,'shipping.manage','Управување со пратки'),(12,'installment.view','Преглед на рати'),
 (13,'installment.manage','Управување со рати'),(14,'return.view','Преглед на враќања'),
 (15,'return.approve','Одобрување враќање'),(16,'support.view','Преглед на пријави'),
 (17,'support.resolve','Решавање пријави'),(18,'customer.view','Преглед на купувачи'),
 (19,'customer.edit','Измена на купувачи'),(20,'report.sales','Извештаи за продажба'),
 (21,'report.finance','Финансиски извештаи'),(22,'employee.manage','Управување со вработени'),
 (23,'role.manage','Управување со улоги и дозволи'),(24,'review.moderate','Модерирање рецензии');

-- Матрица улога → дозволи
INSERT INTO role_permission (role_id, permission_id)
SELECT 1, permission_id FROM permission                                   -- администратор: сè
UNION ALL SELECT 2, p FROM unnest(ARRAY[1,4,7,9,12,14,15,16,18,20,21,22,24]) p
UNION ALL SELECT 3, p FROM unnest(ARRAY[1,4,5,6,7,11]) p
UNION ALL SELECT 4, p FROM unnest(ARRAY[1,4,7,8,9,11,18]) p
UNION ALL SELECT 5, p FROM unnest(ARRAY[1,7,14,16,17,18,19]) p
UNION ALL SELECT 6, p FROM unnest(ARRAY[1,4,7,10,14,15]) p
UNION ALL SELECT 7, p FROM unnest(ARRAY[7,10,12,13,20,21]) p
UNION ALL SELECT 8, p FROM unnest(ARRAY[1,2,3,20,24]) p;

-- 150 вработени: од базенот на уникатни имиња (македонски), плата според улога (во денари).
-- Телефон: индекси 6.000.000+ во македонскиот простор → различни од сите купувачи.
INSERT INTO employee (employee_id, name, surname, email, password, phone, created_at, is_active, salary)
SELECT p.employee_id, p.name, p.surname,
       p.name_lat || '.' || p.surname_lat || '@techshop.mk',
       '$2b$12$' || substr(md5('emp' || p.employee_id) || md5('pw' || p.employee_id), 1, 53),
       seed.mobile('MK', 6000000 + p.employee_id, true),
       timestamp '2020-03-01' + random() * (timestamp '2026-06-01' - timestamp '2020-03-01'),
       random() > 0.08,
       round(((CASE r.role_id WHEN 1 THEN 95000 WHEN 2 THEN 85000 WHEN 3 THEN 32000 WHEN 4 THEN 36000
                              WHEN 5 THEN 34000 WHEN 6 THEN 36000 WHEN 7 THEN 55000 ELSE 50000 END) * (0.9 + random() * 0.3))::numeric, -2)
FROM seed.person_pool p
CROSS JOIN LATERAL (SELECT CASE WHEN p.employee_id <= 3 THEN 1 WHEN p.employee_id <= 10 THEN 2 WHEN p.employee_id <= 55 THEN 3
                                WHEN p.employee_id <= 85 THEN 4 WHEN p.employee_id <= 115 THEN 5 WHEN p.employee_id <= 130 THEN 6
                                WHEN p.employee_id <= 142 THEN 7 ELSE 8 END AS role_id) r
WHERE p.is_employee;

-- Секој вработен ја има главната улога; 15% имаат и втора
INSERT INTO employee_role (employee_id, role_id)
SELECT i, CASE WHEN i <= 3 THEN 1 WHEN i <= 10 THEN 2 WHEN i <= 55 THEN 3 WHEN i <= 85 THEN 4
               WHEN i <= 115 THEN 5 WHEN i <= 130 THEN 6 WHEN i <= 142 THEN 7 ELSE 8 END
FROM generate_series(1, 150) i;

INSERT INTO employee_role (employee_id, role_id)
SELECT employee_id, CASE role_id WHEN 5 THEN 6 WHEN 6 THEN 5 WHEN 3 THEN 4 ELSE 5 END
FROM employee_role
WHERE role_id IN (3, 5, 6) AND random() < 0.15
ON CONFLICT DO NOTHING;
