-- =====================================================================
--  Constraint tests for ddl_v2.sql
--  Run on a database where ddl_v2.sql was just executed (empty tables).
--  Everything runs inside one transaction and is ROLLED BACK at the end,
--  so the database stays empty.
--  Output: one NOTICE line per test -> PASS / FAIL.
--  Usage: psql -d tech_shop -f 00_ddl/constraint_tests.sql
-- =====================================================================
BEGIN;

CREATE FUNCTION pg_temp.expect_ok(label text, stmt text) RETURNS void AS $$
BEGIN
    EXECUTE stmt;
    RAISE NOTICE 'PASS  [ok]    %', label;
EXCEPTION WHEN others THEN
    RAISE NOTICE 'FAIL  [ok]    % -> %', label, SQLERRM;
END $$ LANGUAGE plpgsql;

CREATE FUNCTION pg_temp.expect_error(label text, stmt text) RETURNS void AS $$
BEGIN
    EXECUTE stmt;
    RAISE NOTICE 'FAIL  [error] % -> statement was accepted', label;
EXCEPTION WHEN others THEN
    RAISE NOTICE 'PASS  [error] % -> %', label, SQLERRM;
END $$ LANGUAGE plpgsql;

-- ---------- valid base data ----------
SELECT pg_temp.expect_ok('customer valid (+389 phone)',
  $q$INSERT INTO customer(customer_id,name,surname,email,password,phone) VALUES (1,'Ana','Petrova','ana@mail.mk','hash12345','+38970123456')$q$);
SELECT pg_temp.expect_ok('customer valid (0 phone)',
  $q$INSERT INTO customer(customer_id,name,surname,email,password,phone) VALUES (2,'Bojan','Iliev','bojan@mail.mk','hash12345','070123456')$q$);
SELECT pg_temp.expect_ok('address + address_customer valid',
  $q$INSERT INTO address(address_id,street,number,city) VALUES (1,'Partizanska','10','Skopje'),(2,'Shirok Sokak','5','Bitola');
     INSERT INTO address_customer(customer_id,address_id) VALUES (1,1),(2,2)$q$);
SELECT pg_temp.expect_ok('category + product valid',
  $q$INSERT INTO category(category_id,name) VALUES (1,'Laptops');
     INSERT INTO product(product_id,name,price,category_id) VALUES (1,'ThinkPad X1',1500,1)$q$);
SELECT pg_temp.expect_ok('employee valid',
  $q$INSERT INTO employee(employee_id,name,surname,email,password) VALUES (1,'Marko','Stojanov','marko@shop.mk','hash12345')$q$);
SELECT pg_temp.expect_ok('warehouse valid',
  $q$INSERT INTO warehouse(warehouse_id,name,city) VALUES (1,'Skopje-1','Skopje')$q$);
SELECT pg_temp.expect_ok('order + order_item valid',
  $q$INSERT INTO orders(order_id,customer_id,address_id,method_payment) VALUES (1,1,1,'card');
     INSERT INTO order_item(order_item_id,order_id,product_id,quantity,unit_price) VALUES (1,1,1,1,1500)$q$);
SELECT pg_temp.expect_ok('serial sold with order_item',
  $q$INSERT INTO serial_number(serial_code,product_id,warehouse_id,status,order_item_id) VALUES ('SN-0001',1,1,'sold',1)$q$);

-- ---------- customer / employee / supplier ----------
SELECT pg_temp.expect_error('customer email unique (case-insensitive)',
  $q$INSERT INTO customer(name,surname,email,password) VALUES ('X','Y','ANA@mail.mk','hash12345')$q$);
SELECT pg_temp.expect_error('customer email format',
  $q$INSERT INTO customer(name,surname,email,password) VALUES ('X','Y','not-an-email','hash12345')$q$);
SELECT pg_temp.expect_error('customer empty name',
  $q$INSERT INTO customer(name,surname,email,password) VALUES ('','Y','x1@mail.mk','hash12345')$q$);
SELECT pg_temp.expect_error('customer password length >= 8',
  $q$INSERT INTO customer(name,surname,email,password) VALUES ('X','Y','x2@mail.mk','short')$q$);
SELECT pg_temp.expect_error('customer phone format',
  $q$INSERT INTO customer(name,surname,email,password,phone) VALUES ('X','Y','x3@mail.mk','hash12345','12345')$q$);
SELECT pg_temp.expect_error('employee salary >= 0',
  $q$INSERT INTO employee(name,surname,email,password,salary) VALUES ('X','Y','e2@shop.mk','hash12345',-1)$q$);
SELECT pg_temp.expect_error('supplier email unique',
  $q$INSERT INTO supplier(name,email) VALUES ('A','s@sup.com'),('B','S@sup.com')$q$);
SELECT pg_temp.expect_error('customer_attribute unique (customer,name)',
  $q$INSERT INTO customer_attribute(customer_id,name,text) VALUES (1,'lang','mk'),(1,'lang','en')$q$);
SELECT pg_temp.expect_error('address_customer unique pair',
  $q$INSERT INTO address_customer(customer_id,address_id) VALUES (1,1)$q$);

-- ---------- catalog ----------
SELECT pg_temp.expect_error('category name unique under same parent',
  $q$INSERT INTO category(name) VALUES ('Laptops')$q$);
SELECT pg_temp.expect_error('category cannot be own parent',
  $q$INSERT INTO category(category_id,name,parent_category_id) VALUES (99,'Self',99)$q$);
SELECT pg_temp.expect_error('product price > 0',
  $q$INSERT INTO product(name,price,category_id) VALUES ('Free',0,1)$q$);
SELECT pg_temp.expect_error('product category FK',
  $q$INSERT INTO product(name,price,category_id) VALUES ('Orphan',10,999)$q$);
SELECT pg_temp.expect_error('product_attribute unique (product,name)',
  $q$INSERT INTO product_attribute(product_id,name,value) VALUES (1,'RAM','16GB'),(1,'RAM','32GB')$q$);
SELECT pg_temp.expect_error('price_history price > 0',
  $q$INSERT INTO price_history(product_id,date,price) VALUES (1,'2026-01-01',0)$q$);
SELECT pg_temp.expect_error('price_history one per product/day',
  $q$INSERT INTO price_history(product_id,date,price) VALUES (1,'2026-01-01',10),(1,'2026-01-01',11)$q$);
SELECT pg_temp.expect_error('promotion percent in (0,100]',
  $q$INSERT INTO promotion(product_id,percent,start_date,end_date) VALUES (1,0,'2026-01-01','2026-01-31')$q$);
SELECT pg_temp.expect_error('promotion start <= end',
  $q$INSERT INTO promotion(product_id,percent,start_date,end_date) VALUES (1,10,'2026-02-01','2026-01-01')$q$);
SELECT pg_temp.expect_error('category with products cannot be deleted (RESTRICT)',
  $q$DELETE FROM category WHERE category_id = 1$q$);

-- ---------- orders ----------
SELECT pg_temp.expect_error('order address must belong to customer',
  $q$INSERT INTO orders(customer_id,address_id,method_payment) VALUES (1,2,'card')$q$);
SELECT pg_temp.expect_error('paid order needs date_paid',
  $q$INSERT INTO orders(customer_id,address_id,method_payment,status) VALUES (1,1,'card','paid')$q$);
SELECT pg_temp.expect_error('date_paid >= date_ordered',
  $q$INSERT INTO orders(customer_id,address_id,method_payment,status,date_ordered,date_paid) VALUES (1,1,'card','paid','2026-02-01','2026-01-01')$q$);
SELECT pg_temp.expect_error('order status domain',
  $q$INSERT INTO orders(customer_id,address_id,method_payment,status) VALUES (1,1,'card','lost')$q$);
SELECT pg_temp.expect_error('payment method domain',
  $q$INSERT INTO orders(customer_id,address_id,method_payment) VALUES (1,1,'bitcoin')$q$);
SELECT pg_temp.expect_error('customer with orders cannot be deleted (RESTRICT)',
  $q$DELETE FROM customer WHERE customer_id = 1$q$);
SELECT pg_temp.expect_error('order_item quantity > 0',
  $q$INSERT INTO order_item(order_id,product_id,quantity,unit_price) VALUES (1,1,0,10)$q$);
SELECT pg_temp.expect_error('order_item product once per order',
  $q$INSERT INTO order_item(order_id,product_id,quantity,unit_price) VALUES (1,1,1,1500)$q$);
SELECT pg_temp.expect_error('installment unique number per order',
  $q$INSERT INTO installments(order_id,installment_no,amount,due_date) VALUES (1,1,100,'2026-02-01'),(1,1,100,'2026-03-01')$q$);
SELECT pg_temp.expect_error('installment amount > 0',
  $q$INSERT INTO installments(order_id,installment_no,amount,due_date) VALUES (1,2,0,'2026-02-01')$q$);
SELECT pg_temp.expect_error('shipping delivered needs delivered_date',
  $q$INSERT INTO shipping(status) VALUES ('delivered')$q$);
SELECT pg_temp.expect_error('shipping tracking_number unique',
  $q$INSERT INTO shipping(tracking_number) VALUES ('TRK1'),('TRK1')$q$);

-- ---------- inventory ----------
SELECT pg_temp.expect_error('serial_code unique',
  $q$INSERT INTO serial_number(serial_code,product_id,warehouse_id) VALUES ('SN-0001',1,1)$q$);
SELECT pg_temp.expect_error('sold serial needs order_item',
  $q$INSERT INTO serial_number(serial_code,product_id,warehouse_id,status) VALUES ('SN-0002',1,1,'sold')$q$);
SELECT pg_temp.expect_error('warehouse with stock cannot be deleted (RESTRICT)',
  $q$DELETE FROM warehouse WHERE warehouse_id = 1$q$);

-- ---------- after-sales ----------
SELECT pg_temp.expect_error('review rating 1..5',
  $q$INSERT INTO review(order_item_id,rating) VALUES (1,6)$q$);
SELECT pg_temp.expect_error('one review per order_item',
  $q$INSERT INTO review(order_item_id,rating) VALUES (1,5),(1,4)$q$);
SELECT pg_temp.expect_error('decided return needs employee',
  $q$INSERT INTO returns(order_item_id,status) VALUES (1,'approved')$q$);
SELECT pg_temp.expect_ok('decided return with employee',
  $q$INSERT INTO returns(order_item_id,status,employee_id) VALUES (1,'approved',1)$q$);
SELECT pg_temp.expect_error('solved support report needs resolved_at',
  $q$INSERT INTO customer_support_report(customer_id,complaint,issue_solved) VALUES (1,'Broken screen',true)$q$);
SELECT pg_temp.expect_error('wishlist product once',
  $q$INSERT INTO wishlist(wishlist_id,customer_id) VALUES (1,1);
     INSERT INTO wishlist_items(wishlist_id,product_id) VALUES (1,1),(1,1)$q$);

ROLLBACK;
