# Речник на податоци (data dictionary)

> Автоматски генерирано од базата со `scripts/data_dictionary.sql` на 2026-10-20 18:11. Не уредувај рачно.

Вкупно табели: 27

## address

_Адреси за достава._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `address_id` | integer | да | identity |
| 2 | `street` | varchar(100) | да |  |
| 3 | `number` | varchar(20) |  |  |
| 4 | `city` | varchar(100) | да |  |
| 5 | `country` | varchar(100) | да | 'North Macedonia'::character varying |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `address_pkey` | PK | `PRIMARY KEY (address_id)` |

## address_customer

_M:N врска купувач–адреса; цел на композитниот FK од orders._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `address_customer_id` | integer | да | identity |
| 2 | `customer_id` | integer | да |  |
| 3 | `address_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `address_customer_pkey` | PK | `PRIMARY KEY (address_customer_id)` |
| `fk_address_customer_address` | FK | `FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_address_customer_customer` | FK | `FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_address_customer` | UNIQUE | `UNIQUE (customer_id, address_id)` |

## category

_Хиерархија на категории (parent_category_id)._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `category_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `description` | text |  |  |
| 4 | `parent_category_id` | integer |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `category_pkey` | PK | `PRIMARY KEY (category_id)` |
| `fk_category_self` | FK | `FOREIGN KEY (parent_category_id) REFERENCES category(category_id) ON UPDATE CASCADE ON DELETE SET NULL` |
| `uq_category_name` | UNIQUE | `UNIQUE NULLS NOT DISTINCT (parent_category_id, name)` |
| `category_name_check` | CHECK | `CHECK (((name)::text <> ''::text))` |
| `chk_category_not_self` | CHECK | `CHECK (((parent_category_id IS NULL) OR (parent_category_id <> category_id)))` |

## customer

_Регистрирани купувачи. Не се бришат, се деактивираат со is_active._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `customer_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `surname` | varchar(100) | да |  |
| 4 | `email` | varchar(100) | да |  |
| 5 | `password` | varchar(255) | да |  |
| 6 | `phone` | varchar(20) |  |  |
| 7 | `created_at` | timestamp | да | CURRENT_TIMESTAMP |
| 8 | `is_active` | boolean | да | true |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `customer_pkey` | PK | `PRIMARY KEY (customer_id)` |
| `uq_customer_email` | UNIQUE INDEX | `CREATE UNIQUE INDEX uq_customer_email ON public.customer USING btree (lower((email)::text))` |
| `customer_email_check` | CHECK | `CHECK (((email)::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))` |
| `customer_name_check` | CHECK | `CHECK (((name)::text <> ''::text))` |
| `customer_password_check` | CHECK | `CHECK ((length((password)::text) >= 8))` |
| `customer_phone_check` | CHECK | `CHECK (((phone IS NULL) OR ((phone)::text ~ '^(\+389[0-9]{8}\|0[0-9]{8})$'::text)))` |
| `customer_surname_check` | CHECK | `CHECK (((surname)::text <> ''::text))` |

## customer_attribute

_Проширливи атрибути на купувач (име–вредност), без промена на customer._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `attribute_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `text` | varchar(255) |  |  |
| 4 | `customer_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `customer_attribute_pkey` | PK | `PRIMARY KEY (attribute_id)` |
| `fk_customer_attribute_customer` | FK | `FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_customer_attribute` | UNIQUE | `UNIQUE (customer_id, name)` |

## customer_support_report

_Пријави/поплаки до корисничка поддршка._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `report_id` | bigint | да | identity |
| 2 | `complaint` | text | да |  |
| 3 | `date` | timestamp | да | CURRENT_TIMESTAMP |
| 4 | `issue_solved` | boolean | да | false |
| 5 | `resolved_at` | timestamp |  |  |
| 6 | `employee_id` | integer |  |  |
| 7 | `customer_id` | integer | да |  |
| 8 | `order_id` | bigint |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `customer_support_report_pkey` | PK | `PRIMARY KEY (report_id)` |
| `fk_support_customer` | FK | `FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_support_employee` | FK | `FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON UPDATE CASCADE ON DELETE SET NULL` |
| `fk_support_order` | FK | `FOREIGN KEY (order_id) REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE SET NULL` |
| `chk_support_resolved` | CHECK | `CHECK (((NOT issue_solved) OR (resolved_at IS NOT NULL)))` |
| `customer_support_report_complaint_check` | CHECK | `CHECK ((complaint <> ''::text))` |

## employee

_Вработени во продавницата; email уникатен без разлика на големи/мали букви._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `employee_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `surname` | varchar(100) | да |  |
| 4 | `email` | varchar(100) | да |  |
| 5 | `password` | varchar(255) | да |  |
| 6 | `phone` | varchar(20) |  |  |
| 7 | `created_at` | timestamp | да | CURRENT_TIMESTAMP |
| 8 | `is_active` | boolean | да | true |
| 9 | `salary` | numeric(10,2) |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `employee_pkey` | PK | `PRIMARY KEY (employee_id)` |
| `uq_employee_email` | UNIQUE INDEX | `CREATE UNIQUE INDEX uq_employee_email ON public.employee USING btree (lower((email)::text))` |
| `employee_email_check` | CHECK | `CHECK (((email)::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))` |
| `employee_name_check` | CHECK | `CHECK (((name)::text <> ''::text))` |
| `employee_password_check` | CHECK | `CHECK ((length((password)::text) >= 8))` |
| `employee_phone_check` | CHECK | `CHECK (((phone IS NULL) OR ((phone)::text ~ '^(\+389[0-9]{8}\|0[0-9]{8})$'::text)))` |
| `employee_salary_check` | CHECK | `CHECK (((salary IS NULL) OR (salary >= (0)::numeric)))` |
| `employee_surname_check` | CHECK | `CHECK (((surname)::text <> ''::text))` |

## employee_role

_M:N врска вработен–улога; вработен може да има повеќе улоги._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `employee_role_id` | integer | да | identity |
| 2 | `employee_id` | integer | да |  |
| 3 | `role_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `employee_role_pkey` | PK | `PRIMARY KEY (employee_role_id)` |
| `fk_employee_role_employee` | FK | `FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_employee_role_role` | FK | `FOREIGN KEY (role_id) REFERENCES role(role_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_employee_role` | UNIQUE | `UNIQUE (employee_id, role_id)` |

## installments

_Рати за нарачка платена на рати._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `installment_id` | bigint | да | identity |
| 2 | `installment_no` | smallint | да |  |
| 3 | `amount` | numeric(12,2) | да |  |
| 4 | `due_date` | date | да |  |
| 5 | `paid_at` | timestamp |  |  |
| 6 | `bank` | varchar(100) |  |  |
| 7 | `order_id` | bigint | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `installments_pkey` | PK | `PRIMARY KEY (installment_id)` |
| `fk_installments_order` | FK | `FOREIGN KEY (order_id) REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_installment` | UNIQUE | `UNIQUE (order_id, installment_no)` |
| `installments_amount_check` | CHECK | `CHECK ((amount > (0)::numeric))` |
| `installments_installment_no_check` | CHECK | `CHECK (((installment_no >= 1) AND (installment_no <= 60)))` |

## order_item

_Ставки во нарачка; unit_price е цената во моментот на купување._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `order_item_id` | bigint | да | identity |
| 2 | `status` | varchar(50) | да | 'pending'::character varying |
| 3 | `order_id` | bigint | да |  |
| 4 | `product_id` | integer | да |  |
| 5 | `quantity` | integer | да |  |
| 6 | `unit_price` | numeric(10,2) | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `order_item_pkey` | PK | `PRIMARY KEY (order_item_id)` |
| `fk_order_item_order` | FK | `FOREIGN KEY (order_id) REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_order_item_product` | FK | `FOREIGN KEY (product_id) REFERENCES product(product_id) ON UPDATE CASCADE ON DELETE RESTRICT` |
| `uq_order_item` | UNIQUE | `UNIQUE (order_id, product_id)` |
| `order_item_quantity_check` | CHECK | `CHECK ((quantity > 0))` |
| `order_item_status_check` | CHECK | `CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'processed'::character varying, 'shipped'::character varying, 'delivered'::character varying, 'cancelled'::character varying])::text[])))` |
| `order_item_unit_price_check` | CHECK | `CHECK ((unit_price >= (0)::numeric))` |

## orders

_Нарачки; amount е збир на ставките, адресата мора да е на купувачот._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `order_id` | bigint | да | identity |
| 2 | `date_ordered` | timestamp | да | CURRENT_TIMESTAMP |
| 3 | `status` | varchar(50) | да | 'pending'::character varying |
| 4 | `date_paid` | timestamp |  |  |
| 5 | `amount` | numeric(12,2) | да | 0 |
| 6 | `method_payment` | varchar(50) | да |  |
| 7 | `customer_id` | integer | да |  |
| 8 | `address_id` | integer | да |  |
| 9 | `shipping_id` | bigint |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `orders_pkey` | PK | `PRIMARY KEY (order_id)` |
| `fk_orders_customer` | FK | `FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT` |
| `fk_orders_customer_address` | FK | `FOREIGN KEY (customer_id, address_id) REFERENCES address_customer(customer_id, address_id) ON UPDATE CASCADE ON DELETE RESTRICT` |
| `fk_orders_shipping` | FK | `FOREIGN KEY (shipping_id) REFERENCES shipping(shipping_id) ON UPDATE CASCADE ON DELETE SET NULL` |
| `orders_shipping_id_key` | UNIQUE | `UNIQUE (shipping_id)` |
| `chk_orders_paid_has_date` | CHECK | `CHECK ((((status)::text <> ALL ((ARRAY['paid'::character varying, 'shipped'::character varying, 'delivered'::character varying])::text[])) OR (date_paid IS NOT NULL)))` |
| `chk_orders_payment_date` | CHECK | `CHECK (((date_paid IS NULL) OR (date_paid >= date_ordered)))` |
| `orders_amount_check` | CHECK | `CHECK ((amount >= (0)::numeric))` |
| `orders_method_payment_check` | CHECK | `CHECK (((method_payment)::text = ANY ((ARRAY['card'::character varying, 'cash_on_delivery'::character varying, 'bank_transfer'::character varying, 'installments'::character varying])::text[])))` |
| `orders_status_check` | CHECK | `CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'paid'::character varying, 'shipped'::character varying, 'delivered'::character varying, 'cancelled'::character varying])::text[])))` |

## permission

_Дозволи во системот, со уникатен код (пр. order.refund)._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `permission_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `description` | text |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `permission_pkey` | PK | `PRIMARY KEY (permission_id)` |
| `permission_name_key` | UNIQUE | `UNIQUE (name)` |

## price_history

_Историја на продажната цена, најмногу една промена по ден._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `price_history_id` | bigint | да | identity |
| 2 | `date` | date | да | CURRENT_DATE |
| 3 | `price` | numeric(10,2) | да |  |
| 4 | `product_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `price_history_pkey` | PK | `PRIMARY KEY (price_history_id)` |
| `fk_price_history_product` | FK | `FOREIGN KEY (product_id) REFERENCES product(product_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_price_history` | UNIQUE | `UNIQUE (product_id, date)` |
| `price_history_price_check` | CHECK | `CHECK ((price > (0)::numeric))` |

## product

_Производи во каталогот; price е тековната продажна цена._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `product_id` | integer | да | identity |
| 2 | `name` | varchar(150) | да |  |
| 3 | `description` | text |  |  |
| 4 | `price` | numeric(10,2) | да |  |
| 5 | `is_active` | boolean | да | true |
| 6 | `created_at` | timestamp | да | CURRENT_TIMESTAMP |
| 7 | `category_id` | integer | да |  |
| 8 | `manufacturer` | varchar(100) |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `product_pkey` | PK | `PRIMARY KEY (product_id)` |
| `fk_product_category` | FK | `FOREIGN KEY (category_id) REFERENCES category(category_id) ON UPDATE CASCADE ON DELETE RESTRICT` |
| `product_name_check` | CHECK | `CHECK (((name)::text <> ''::text))` |
| `product_price_check` | CHECK | `CHECK ((price > (0)::numeric))` |

## product_attribute

_Технички карактеристики на производ (RAM, SSD, екран...)._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `product_attribute_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `value` | varchar(255) | да |  |
| 4 | `product_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `product_attribute_pkey` | PK | `PRIMARY KEY (product_attribute_id)` |
| `fk_product_attribute_product` | FK | `FOREIGN KEY (product_id) REFERENCES product(product_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_product_attribute` | UNIQUE | `UNIQUE (product_id, name)` |

## product_supplier

_M:N врска производ–добавувач, со набавна цена._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `product_supplier_id` | integer | да | identity |
| 2 | `product_id` | integer | да |  |
| 3 | `supplier_id` | integer | да |  |
| 4 | `purchase_price` | numeric(10,2) |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `product_supplier_pkey` | PK | `PRIMARY KEY (product_supplier_id)` |
| `fk_product_supplier_product` | FK | `FOREIGN KEY (product_id) REFERENCES product(product_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_product_supplier_supplier` | FK | `FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_product_supplier` | UNIQUE | `UNIQUE (product_id, supplier_id)` |
| `product_supplier_purchase_price_check` | CHECK | `CHECK (((purchase_price IS NULL) OR (purchase_price > (0)::numeric)))` |

## promotion

_Процентуален попуст на производ во временски период._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `promotion_id` | integer | да | identity |
| 2 | `percent` | numeric(5,2) | да |  |
| 3 | `start_date` | date | да |  |
| 4 | `end_date` | date | да |  |
| 5 | `product_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `promotion_pkey` | PK | `PRIMARY KEY (promotion_id)` |
| `fk_promotion_product` | FK | `FOREIGN KEY (product_id) REFERENCES product(product_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `chk_promotion_dates` | CHECK | `CHECK ((start_date <= end_date))` |
| `promotion_percent_check` | CHECK | `CHECK (((percent > (0)::numeric) AND (percent <= (100)::numeric)))` |

## returns

_Барања за враќање на ставка и нивна обработка од вработен._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `return_id` | bigint | да | identity |
| 2 | `date` | date | да | CURRENT_DATE |
| 3 | `reason` | varchar(255) |  |  |
| 4 | `quantity` | integer | да | 1 |
| 5 | `status` | varchar(50) | да | 'requested'::character varying |
| 6 | `resolved_at` | timestamp |  |  |
| 7 | `order_item_id` | bigint | да |  |
| 8 | `employee_id` | integer |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `returns_pkey` | PK | `PRIMARY KEY (return_id)` |
| `fk_returns_employee` | FK | `FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON UPDATE CASCADE ON DELETE SET NULL` |
| `fk_returns_order_item` | FK | `FOREIGN KEY (order_item_id) REFERENCES order_item(order_item_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `chk_returns_decided` | CHECK | `CHECK ((((status)::text = 'requested'::text) OR (employee_id IS NOT NULL)))` |
| `returns_quantity_check` | CHECK | `CHECK ((quantity > 0))` |
| `returns_status_check` | CHECK | `CHECK (((status)::text = ANY ((ARRAY['requested'::character varying, 'approved'::character varying, 'rejected'::character varying, 'completed'::character varying])::text[])))` |

## review

_Рецензија (1–5) за купена ставка; најмногу една по ставка._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `review_id` | bigint | да | identity |
| 2 | `rating` | smallint | да |  |
| 3 | `date` | timestamp | да | CURRENT_TIMESTAMP |
| 4 | `comment` | text |  |  |
| 5 | `order_item_id` | bigint | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `review_pkey` | PK | `PRIMARY KEY (review_id)` |
| `fk_review_order_item` | FK | `FOREIGN KEY (order_item_id) REFERENCES order_item(order_item_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `review_order_item_id_key` | UNIQUE | `UNIQUE (order_item_id)` |
| `review_rating_check` | CHECK | `CHECK (((rating >= 1) AND (rating <= 5)))` |

## role

_Улоги на вработени (администратор, магационер, оператор за нарачки, поддршка)._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `role_id` | integer | да | identity |
| 2 | `role` | varchar(50) | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `role_pkey` | PK | `PRIMARY KEY (role_id)` |
| `role_role_key` | UNIQUE | `UNIQUE (role)` |
| `role_role_check` | CHECK | `CHECK (((role)::text <> ''::text))` |

## role_permission

_M:N врска улога–дозвола._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `role_permission_id` | integer | да | identity |
| 2 | `role_id` | integer | да |  |
| 3 | `permission_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `role_permission_pkey` | PK | `PRIMARY KEY (role_permission_id)` |
| `fk_role_permission_permission` | FK | `FOREIGN KEY (permission_id) REFERENCES permission(permission_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_role_permission_role` | FK | `FOREIGN KEY (role_id) REFERENCES role(role_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_role_permission` | UNIQUE | `UNIQUE (role_id, permission_id)` |

## serial_number

_Поединечни уреди со сериски број: магацин, статус и (ако е продаден) ставка._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `serial_number_id` | bigint | да | identity |
| 2 | `serial_code` | varchar(64) | да |  |
| 3 | `status` | varchar(20) | да | 'in_stock'::character varying |
| 4 | `received_at` | timestamp | да | CURRENT_TIMESTAMP |
| 5 | `product_id` | integer | да |  |
| 6 | `warehouse_id` | integer | да |  |
| 7 | `order_item_id` | bigint |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `serial_number_pkey` | PK | `PRIMARY KEY (serial_number_id)` |
| `fk_serial_order_item` | FK | `FOREIGN KEY (order_item_id) REFERENCES order_item(order_item_id) ON UPDATE CASCADE ON DELETE SET NULL` |
| `fk_serial_product` | FK | `FOREIGN KEY (product_id) REFERENCES product(product_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_serial_warehouse` | FK | `FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id) ON UPDATE CASCADE ON DELETE RESTRICT` |
| `serial_number_serial_code_key` | UNIQUE | `UNIQUE (serial_code)` |
| `chk_serial_sold` | CHECK | `CHECK ((((status)::text <> 'sold'::text) OR (order_item_id IS NOT NULL)))` |
| `serial_number_status_check` | CHECK | `CHECK (((status)::text = ANY ((ARRAY['in_stock'::character varying, 'reserved'::character varying, 'sold'::character varying, 'returned'::character varying, 'defective'::character varying])::text[])))` |

## shipping

_Пратка за една нарачка: карго, tracking број, статус._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `shipping_id` | bigint | да | identity |
| 2 | `date` | date | да | CURRENT_DATE |
| 3 | `delivered_date` | date |  |  |
| 4 | `status` | varchar(50) | да | 'preparing'::character varying |
| 5 | `carrier` | varchar(100) |  |  |
| 6 | `tracking_number` | varchar(100) |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `shipping_pkey` | PK | `PRIMARY KEY (shipping_id)` |
| `shipping_tracking_number_key` | UNIQUE | `UNIQUE (tracking_number)` |
| `chk_shipping_dates` | CHECK | `CHECK (((delivered_date IS NULL) OR (delivered_date >= date)))` |
| `chk_shipping_delivered` | CHECK | `CHECK ((((status)::text <> 'delivered'::text) OR (delivered_date IS NOT NULL)))` |
| `shipping_status_check` | CHECK | `CHECK (((status)::text = ANY ((ARRAY['preparing'::character varying, 'in_transit'::character varying, 'delivered'::character varying, 'returned'::character varying])::text[])))` |

## supplier

_Добавувачи на производи._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `supplier_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `company` | varchar(100) |  |  |
| 4 | `email` | varchar(100) |  |  |
| 5 | `phone` | varchar(20) |  |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `supplier_pkey` | PK | `PRIMARY KEY (supplier_id)` |
| `uq_supplier_email` | UNIQUE INDEX | `CREATE UNIQUE INDEX uq_supplier_email ON public.supplier USING btree (lower((email)::text))` |
| `supplier_email_check` | CHECK | `CHECK (((email IS NULL) OR ((email)::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)))` |
| `supplier_name_check` | CHECK | `CHECK (((name)::text <> ''::text))` |
| `supplier_phone_check` | CHECK | `CHECK (((phone IS NULL) OR ((phone)::text ~ '^\+?[0-9]{6,15}$'::text)))` |

## warehouse

_Магацини._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `warehouse_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да |  |
| 3 | `city` | varchar(100) | да |  |
| 4 | `number` | varchar(20) |  |  |
| 5 | `street` | varchar(100) |  |  |
| 6 | `country` | varchar(100) | да | 'North Macedonia'::character varying |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `warehouse_pkey` | PK | `PRIMARY KEY (warehouse_id)` |
| `warehouse_name_key` | UNIQUE | `UNIQUE (name)` |

## wishlist

_Листи на желби на купувач._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `wishlist_id` | integer | да | identity |
| 2 | `name` | varchar(100) | да | 'Default'::character varying |
| 3 | `created_at` | timestamp | да | CURRENT_TIMESTAMP |
| 4 | `customer_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `wishlist_pkey` | PK | `PRIMARY KEY (wishlist_id)` |
| `fk_wishlist_customer` | FK | `FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_wishlist_name` | UNIQUE | `UNIQUE (customer_id, name)` |

## wishlist_items

_Производи во листа на желби._

| # | Колона | Тип | NOT NULL | Default |
| --- | --- | --- | --- | --- |
| 1 | `wishlist_item_id` | bigint | да | identity |
| 2 | `added_at` | timestamp | да | CURRENT_TIMESTAMP |
| 3 | `wishlist_id` | integer | да |  |
| 4 | `product_id` | integer | да |  |

| Ограничување | Тип | Дефиниција |
| --- | --- | --- |
| `wishlist_items_pkey` | PK | `PRIMARY KEY (wishlist_item_id)` |
| `fk_wishlist_items_product` | FK | `FOREIGN KEY (product_id) REFERENCES product(product_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `fk_wishlist_items_wishlist` | FK | `FOREIGN KEY (wishlist_id) REFERENCES wishlist(wishlist_id) ON UPDATE CASCADE ON DELETE CASCADE` |
| `uq_wishlist_product` | UNIQUE | `UNIQUE (wishlist_id, product_id)` |

