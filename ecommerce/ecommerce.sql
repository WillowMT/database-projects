/* ECOMMERCE DATABASE -- Oracle 19c+ / APEX SQL Workshop
   Run once in a FRESH schema using SQL Workshop > SQL Scripts.
   Fictional data; currency THB. No application code. Oracle DDL commits implicitly.
   Exactly 10 tables: customers, addresses, categories, products, orders,
   order_items, shipments, carriers, payments, reviews. Do not rerun over objects.
*/

-- 1. TABLES AND CONSTRAINTS -----------------------------------------
CREATE TABLE customers (
 customer_id NUMBER(6) CONSTRAINT pk_customers PRIMARY KEY,
 full_name VARCHAR2(100) NOT NULL,
 email VARCHAR2(120) NOT NULL CONSTRAINT uq_customer_email UNIQUE,
 phone VARCHAR2(25),
 customer_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 created_on DATE DEFAULT SYSDATE NOT NULL,
 CONSTRAINT ck_customer_status CHECK (customer_status IN ('ACTIVE','SUSPENDED'))
);
CREATE TABLE addresses (
 address_id NUMBER(6) CONSTRAINT pk_addresses PRIMARY KEY,
 customer_id NUMBER(6) NOT NULL CONSTRAINT fk_address_customer REFERENCES customers(customer_id) ON DELETE CASCADE,
 address_label VARCHAR2(30) DEFAULT 'HOME' NOT NULL,
 recipient_name VARCHAR2(100) NOT NULL,
 line1 VARCHAR2(150) NOT NULL,
 district VARCHAR2(80) NOT NULL,
 province VARCHAR2(80) NOT NULL,
 postal_code VARCHAR2(10) NOT NULL,
 country VARCHAR2(60) DEFAULT 'Thailand' NOT NULL,
 CONSTRAINT uq_address_label UNIQUE (customer_id,address_label),
 CONSTRAINT ck_address_label CHECK (address_label IN ('HOME','WORK','OTHER'))
);
CREATE TABLE categories (
 category_id NUMBER(6) CONSTRAINT pk_categories PRIMARY KEY,
 category_name VARCHAR2(60) NOT NULL CONSTRAINT uq_category_name UNIQUE,
 active_flag CHAR(1) DEFAULT 'Y' NOT NULL,
 CONSTRAINT ck_category_active CHECK (active_flag IN ('Y','N'))
);
CREATE TABLE products (
 product_id NUMBER(6) CONSTRAINT pk_products PRIMARY KEY,
 category_id NUMBER(6) NOT NULL CONSTRAINT fk_product_category REFERENCES categories(category_id),
 sku VARCHAR2(30) NOT NULL CONSTRAINT uq_product_sku UNIQUE,
 product_name VARCHAR2(120) NOT NULL,
 list_price NUMBER(10,2) NOT NULL,
 stock_qty NUMBER(8) DEFAULT 0 NOT NULL,
 product_status VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_product_price CHECK (list_price > 0),
 CONSTRAINT ck_product_stock CHECK (stock_qty >= 0),
 CONSTRAINT ck_product_status CHECK (product_status IN ('ACTIVE','DISCONTINUED'))
);
CREATE TABLE carriers (
 carrier_id NUMBER(6) CONSTRAINT pk_carriers PRIMARY KEY,
 carrier_name VARCHAR2(80) NOT NULL CONSTRAINT uq_carrier_name UNIQUE,
 tracking_prefix VARCHAR2(12) NOT NULL CONSTRAINT uq_tracking_prefix UNIQUE,
 service_phone VARCHAR2(25)
);
CREATE TABLE orders (
 order_id NUMBER(6) CONSTRAINT pk_orders PRIMARY KEY,
 customer_id NUMBER(6) NOT NULL CONSTRAINT fk_order_customer REFERENCES customers(customer_id),
 shipping_address_id NUMBER(6) NOT NULL CONSTRAINT fk_order_address REFERENCES addresses(address_id),
 ordered_on DATE DEFAULT SYSDATE NOT NULL,
 order_status VARCHAR2(15) DEFAULT 'NEW' NOT NULL,
 shipping_fee NUMBER(10,2) DEFAULT 0 NOT NULL,
 discount_amount NUMBER(10,2) DEFAULT 0 NOT NULL,
 CONSTRAINT ck_order_status CHECK (order_status IN ('NEW','PAID','FULFILLED','CANCELLED')),
 CONSTRAINT ck_order_shipping CHECK (shipping_fee >= 0),
 CONSTRAINT ck_order_discount CHECK (discount_amount >= 0)
);
CREATE TABLE order_items (
 order_id NUMBER(6) CONSTRAINT fk_item_order REFERENCES orders(order_id) ON DELETE CASCADE,
 product_id NUMBER(6) CONSTRAINT fk_item_product REFERENCES products(product_id),
 quantity NUMBER(6) DEFAULT 1 NOT NULL,
 unit_price NUMBER(10,2) NOT NULL,
 discount_amount NUMBER(10,2) DEFAULT 0 NOT NULL,
 CONSTRAINT pk_order_items PRIMARY KEY (order_id,product_id),
 CONSTRAINT ck_item_quantity CHECK (quantity > 0),
 CONSTRAINT ck_item_price CHECK (unit_price > 0),
 CONSTRAINT ck_item_discount CHECK (discount_amount >= 0 AND discount_amount <= quantity*unit_price)
);
CREATE TABLE shipments (
 shipment_id NUMBER(6) CONSTRAINT pk_shipments PRIMARY KEY,
 order_id NUMBER(6) NOT NULL CONSTRAINT uq_shipment_order UNIQUE,
 carrier_id NUMBER(6) CONSTRAINT fk_shipment_carrier REFERENCES carriers(carrier_id) ON DELETE SET NULL,
 tracking_number VARCHAR2(40) NOT NULL CONSTRAINT uq_tracking_number UNIQUE,
 shipped_on DATE,
 delivered_on DATE,
 shipment_status VARCHAR2(15) DEFAULT 'PENDING' NOT NULL,
 CONSTRAINT fk_shipment_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
 CONSTRAINT ck_shipment_status CHECK (shipment_status IN ('PENDING','SHIPPED','DELIVERED','RETURNED')),
 CONSTRAINT ck_shipment_dates CHECK (delivered_on IS NULL OR (shipped_on IS NOT NULL AND delivered_on >= shipped_on))
);
CREATE TABLE payments (
 payment_id NUMBER(6) CONSTRAINT pk_payments PRIMARY KEY,
 order_id NUMBER(6) NOT NULL CONSTRAINT fk_payment_order REFERENCES orders(order_id),
 paid_on DATE DEFAULT SYSDATE NOT NULL,
 amount NUMBER(10,2) NOT NULL,
 payment_method VARCHAR2(15) NOT NULL,
 payment_reference VARCHAR2(60) NOT NULL CONSTRAINT uq_payment_reference UNIQUE,
 payment_status VARCHAR2(12) DEFAULT 'CAPTURED' NOT NULL,
 CONSTRAINT ck_payment_amount CHECK (amount > 0),
 CONSTRAINT ck_payment_method CHECK (payment_method IN ('CARD','TRANSFER','WALLET','COD')),
 CONSTRAINT ck_payment_status CHECK (payment_status IN ('PENDING','CAPTURED','REFUNDED'))
);
CREATE TABLE reviews (
 review_id NUMBER(6) CONSTRAINT pk_reviews PRIMARY KEY,
 customer_id NUMBER(6) NOT NULL CONSTRAINT fk_review_customer REFERENCES customers(customer_id),
 product_id NUMBER(6) NOT NULL CONSTRAINT fk_review_product REFERENCES products(product_id),
 rating NUMBER(1) NOT NULL,
 review_title VARCHAR2(100) NOT NULL,
 review_text VARCHAR2(500) NOT NULL,
 reviewed_on DATE DEFAULT SYSDATE NOT NULL,
 review_status VARCHAR2(12) DEFAULT 'PUBLISHED' NOT NULL,
 CONSTRAINT uq_customer_product_review UNIQUE (customer_id,product_id),
 CONSTRAINT ck_review_rating CHECK (rating BETWEEN 1 AND 5),
 CONSTRAINT ck_review_status CHECK (review_status IN ('PUBLISHED','HIDDEN'))
);

-- CASCADE removes private addresses and line items with their owning customer/order.
-- SET NULL retains shipment history if a carrier record is removed.
-- Product/category/order/payment history is otherwise protected by restrictive FKs.
CREATE INDEX ix_addresses_customer ON addresses(customer_id);
CREATE INDEX ix_products_category ON products(category_id);
CREATE INDEX ix_orders_customer ON orders(customer_id);
CREATE INDEX ix_orders_address ON orders(shipping_address_id);
CREATE INDEX ix_items_product ON order_items(product_id);
CREATE INDEX ix_shipments_carrier ON shipments(carrier_id);
CREATE INDEX ix_payments_order ON payments(order_id);
CREATE INDEX ix_reviews_product ON reviews(product_id);
CREATE INDEX ix_reviews_customer ON reviews(customer_id);

-- 2. SEED DATA ------------------------------------------------------
INSERT ALL
 INTO customers VALUES (1,'Anan Suri','anan@example.com','0811111001','ACTIVE',DATE '2025-01-10')
 INTO customers VALUES (2,'Maya Chen','maya@example.com','0811111002','ACTIVE',DATE '2025-01-11')
 INTO customers VALUES (3,'James Wilson','james@example.com','0811111003','ACTIVE',DATE '2025-01-12')
 INTO customers VALUES (4,'Sofia Rossi','sofia@example.com','0811111004','ACTIVE',DATE '2025-01-13')
 INTO customers VALUES (5,'Min Thu','min@example.com','0811111005','ACTIVE',DATE '2025-01-14')
 INTO customers VALUES (6,'Yuki Sato','yuki@example.com','0811111006','ACTIVE',DATE '2025-01-15')
 INTO customers VALUES (7,'Lina Park','lina@example.com','0811111007','ACTIVE',DATE '2025-01-16')
 INTO customers VALUES (8,'Noah Brown','noah@example.com','0811111008','ACTIVE',DATE '2025-01-17')
 INTO customers VALUES (9,'Emma Martin','emma@example.com','0811111009','ACTIVE',DATE '2025-01-18')
 INTO customers VALUES (10,'Niran Chai','niran@example.com','0811111010','ACTIVE',DATE '2025-01-19')
SELECT 1 FROM dual;
INSERT ALL
 INTO addresses VALUES (1,1,'HOME','Anan Suri','12 Sukhumvit Road','Watthana','Bangkok','10110','Thailand')
 INTO addresses VALUES (2,2,'HOME','Maya Chen','18 Orchard Lane','Pathum Wan','Bangkok','10330','Thailand')
 INTO addresses VALUES (3,3,'HOME','James Wilson','42 Nimman Road','Mueang','Chiang Mai','50200','Thailand')
 INTO addresses VALUES (4,4,'HOME','Sofia Rossi','77 Beach Road','Mueang','Phuket','83000','Thailand')
 INTO addresses VALUES (5,5,'HOME','Min Thu','9 River Street','Mueang','Khon Kaen','40000','Thailand')
 INTO addresses VALUES (6,6,'HOME','Yuki Sato','5 Market Road','Mueang','Nakhon Ratchasima','30000','Thailand')
 INTO addresses VALUES (7,7,'HOME','Lina Park','81 Hill Road','Mueang','Chiang Mai','50300','Thailand')
 INTO addresses VALUES (8,8,'HOME','Noah Brown','25 Lake Road','Bang Lamung','Chon Buri','20150','Thailand')
 INTO addresses VALUES (9,9,'HOME','Emma Martin','16 Garden Street','Mueang','Udon Thani','41000','Thailand')
 INTO addresses VALUES (10,10,'HOME','Niran Chai','33 Rama IX Road','Huai Khwang','Bangkok','10310','Thailand')
SELECT 1 FROM dual;
INSERT ALL
 INTO categories VALUES (1,'Electronics','Y')
 INTO categories VALUES (2,'Home Office','Y')
 INTO categories VALUES (3,'Kitchen','Y')
 INTO categories VALUES (4,'Fitness','Y')
 INTO categories VALUES (5,'Books','Y')
SELECT 1 FROM dual;
INSERT ALL
 INTO products VALUES (1,1,'ELEC-001','Wireless Mouse',590,40,'ACTIVE')
 INTO products VALUES (2,1,'ELEC-002','USB-C Hub',990,25,'ACTIVE')
 INTO products VALUES (3,2,'HOME-001','Desk Lamp',790,18,'ACTIVE')
 INTO products VALUES (4,2,'HOME-002','Notebook Stand',650,32,'ACTIVE')
 INTO products VALUES (5,3,'KITCH-001','Insulated Bottle',450,50,'ACTIVE')
 INTO products VALUES (6,3,'KITCH-002','Coffee Grinder',1290,12,'ACTIVE')
 INTO products VALUES (7,4,'FIT-001','Yoga Mat',720,20,'ACTIVE')
 INTO products VALUES (8,4,'FIT-002','Resistance Bands',380,45,'ACTIVE')
 INTO products VALUES (9,5,'BOOK-001','SQL Fundamentals',850,30,'ACTIVE')
 INTO products VALUES (10,5,'BOOK-002','Data Modeling Guide',980,15,'ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO carriers VALUES (1,'Thailand Post','THP','1545')
 INTO carriers VALUES (2,'Kerry Express','KEX','1217')
 INTO carriers VALUES (3,'Flash Express','FLH','1436')
 INTO carriers VALUES (4,'DHL Express','DHL','02-345-5000')
 INTO carriers VALUES (5,'J&T Express','JNT','02-009-5678')
SELECT 1 FROM dual;

-- Ten orders and ten payments/shipments; 12 line items prove the M:N relationship.
INSERT ALL
 INTO orders VALUES (1,1,1,DATE '2026-01-05','FULFILLED',50,0)
 INTO orders VALUES (2,2,2,DATE '2026-01-08','FULFILLED',50,30)
 INTO orders VALUES (3,3,3,DATE '2026-01-12','FULFILLED',0,0)
 INTO orders VALUES (4,4,4,DATE '2026-01-16','FULFILLED',80,0)
 INTO orders VALUES (5,5,5,DATE '2026-01-20','FULFILLED',50,20)
 INTO orders VALUES (6,1,1,DATE '2026-01-25','FULFILLED',50,0)
 INTO orders VALUES (7,6,6,DATE '2026-02-01','FULFILLED',0,0)
 INTO orders VALUES (8,7,7,DATE '2026-02-05','FULFILLED',50,0)
 INTO orders VALUES (9,8,8,DATE '2026-02-09','PAID',50,0)
 INTO orders VALUES (10,9,9,DATE '2026-02-14','NEW',50,0)
SELECT 1 FROM dual;
INSERT ALL
 INTO order_items VALUES (1,1,1,550,0)
 INTO order_items VALUES (1,9,1,850,0)
 INTO order_items VALUES (2,2,1,950,30)
 INTO order_items VALUES (3,3,1,790,0)
 INTO order_items VALUES (4,4,2,620,0)
 INTO order_items VALUES (5,5,2,420,20)
 INTO order_items VALUES (6,6,1,1200,0)
 INTO order_items VALUES (7,7,1,720,0)
 INTO order_items VALUES (8,8,3,350,0)
 INTO order_items VALUES (9,10,1,980,0)
 INTO order_items VALUES (9,1,1,590,0)
 INTO order_items VALUES (10,9,1,850,0)
SELECT 1 FROM dual;
INSERT ALL
 INTO shipments VALUES (1,1,1,'THP000001',DATE '2026-01-06',DATE '2026-01-08','DELIVERED')
 INTO shipments VALUES (2,2,2,'KEX000002',DATE '2026-01-09',DATE '2026-01-11','DELIVERED')
 INTO shipments VALUES (3,3,3,'FLH000003',DATE '2026-01-13',DATE '2026-01-15','DELIVERED')
 INTO shipments VALUES (4,4,4,'DHL000004',DATE '2026-01-17',DATE '2026-01-19','DELIVERED')
 INTO shipments VALUES (5,5,5,'JNT000005',DATE '2026-01-21',DATE '2026-01-23','DELIVERED')
 INTO shipments VALUES (6,6,1,'THP000006',DATE '2026-01-26',DATE '2026-01-28','DELIVERED')
 INTO shipments VALUES (7,7,2,'KEX000007',DATE '2026-02-02',DATE '2026-02-04','DELIVERED')
 INTO shipments VALUES (8,8,3,'FLH000008',DATE '2026-02-06',DATE '2026-02-08','DELIVERED')
 INTO shipments VALUES (9,9,4,'DHL000009',DATE '2026-02-10',NULL,'SHIPPED')
 INTO shipments VALUES (10,10,5,'JNT000010',NULL,NULL,'PENDING')
SELECT 1 FROM dual;
INSERT ALL
 INTO payments VALUES (1,1,DATE '2026-01-05',1450,'CARD','PAY-000001','CAPTURED')
 INTO payments VALUES (2,2,DATE '2026-01-08',970,'WALLET','PAY-000002','CAPTURED')
 INTO payments VALUES (3,3,DATE '2026-01-12',790,'TRANSFER','PAY-000003','CAPTURED')
 INTO payments VALUES (4,4,DATE '2026-01-16',1320,'CARD','PAY-000004','CAPTURED')
 INTO payments VALUES (5,5,DATE '2026-01-20',870,'CARD','PAY-000005','CAPTURED')
 INTO payments VALUES (6,6,DATE '2026-01-25',1250,'TRANSFER','PAY-000006','CAPTURED')
 INTO payments VALUES (7,7,DATE '2026-02-01',720,'WALLET','PAY-000007','CAPTURED')
 INTO payments VALUES (8,8,DATE '2026-02-05',1100,'CARD','PAY-000008','CAPTURED')
 INTO payments VALUES (9,9,DATE '2026-02-09',1620,'CARD','PAY-000009','CAPTURED')
 INTO payments VALUES (10,10,DATE '2026-02-14',900,'COD','PAY-000010','PENDING')
SELECT 1 FROM dual;
INSERT ALL
 INTO reviews VALUES (1,1,1,5,'Comfortable mouse','Accurate and comfortable for daily work.',DATE '2026-01-12','PUBLISHED')
 INTO reviews VALUES (2,1,9,5,'Clear introduction','Useful examples for learning SQL.',DATE '2026-01-12','PUBLISHED')
 INTO reviews VALUES (3,2,2,4,'Useful hub','Ports work well with my laptop.',DATE '2026-01-15','PUBLISHED')
 INTO reviews VALUES (4,3,3,5,'Good light','Adjustable brightness for desk work.',DATE '2026-01-18','PUBLISHED')
 INTO reviews VALUES (5,4,4,4,'Stable stand','Supports a 15-inch notebook securely.',DATE '2026-01-22','PUBLISHED')
 INTO reviews VALUES (6,5,5,5,'Keeps drinks cold','Solid bottle for a full workday.',DATE '2026-01-26','PUBLISHED')
 INTO reviews VALUES (7,1,6,4,'Even grind','Compact grinder with consistent results.',DATE '2026-01-31','PUBLISHED')
 INTO reviews VALUES (8,6,7,5,'Comfortable mat','Good grip for home practice.',DATE '2026-02-07','PUBLISHED')
 INTO reviews VALUES (9,7,8,4,'Good starter set','Several useful resistance levels.',DATE '2026-02-11','PUBLISHED')
 INTO reviews VALUES (10,8,10,5,'Helpful reference','Explains normalization clearly.',DATE '2026-02-15','PUBLISHED')
SELECT 1 FROM dual;
COMMIT;

-- 3. VIEWS ----------------------------------------------------------
-- V1: operational multi-table order view, one row per order item.
CREATE OR REPLACE VIEW v_order_details AS
SELECT o.order_id,o.ordered_on,o.order_status,c.full_name AS customer_name,
       p.sku,p.product_name,oi.quantity,oi.unit_price,oi.discount_amount,
       oi.quantity*oi.unit_price-oi.discount_amount AS line_total,
       s.shipment_status,s.tracking_number,cr.carrier_name
FROM orders o
JOIN customers c ON c.customer_id=o.customer_id
JOIN order_items oi ON oi.order_id=o.order_id
JOIN products p ON p.product_id=oi.product_id
LEFT JOIN shipments s ON s.order_id=o.order_id
LEFT JOIN carriers cr ON cr.carrier_id=s.carrier_id;

-- V2: preaggregate independent children first, preventing item/payment fanout.
CREATE OR REPLACE VIEW v_order_summary AS
SELECT o.order_id,o.ordered_on,o.order_status,c.customer_id,c.full_name AS customer_name,
       NVL(i.item_total,0) AS item_total,o.shipping_fee,o.discount_amount,
       NVL(i.item_total,0)+o.shipping_fee-o.discount_amount AS order_total,
       NVL(p.paid_total,0) AS paid_total,
       NVL(i.item_total,0)+o.shipping_fee-o.discount_amount-NVL(p.paid_total,0) AS balance_due
FROM orders o
JOIN customers c ON c.customer_id=o.customer_id
LEFT JOIN (
 SELECT order_id,SUM(quantity*unit_price-discount_amount) AS item_total
 FROM order_items GROUP BY order_id
) i ON i.order_id=o.order_id
LEFT JOIN (
 SELECT order_id,SUM(CASE WHEN payment_status='CAPTURED' THEN amount ELSE 0 END) AS paid_total
 FROM payments GROUP BY order_id
) p ON p.order_id=o.order_id;

-- V3: Top-N customer spend; ordered inline view then ROWNUM outside.
CREATE OR REPLACE VIEW v_top5_customers AS
SELECT customer_id,customer_name,total_spent
FROM (
 SELECT c.customer_id,c.full_name AS customer_name,SUM(s.order_total) AS total_spent
 FROM customers c JOIN v_order_summary s ON s.customer_id=c.customer_id
 WHERE s.order_status<>'CANCELLED'
 GROUP BY c.customer_id,c.full_name
 ORDER BY total_spent DESC,c.customer_id
) WHERE ROWNUM<=5;

-- 4. REQUIRED QUERIES ----------------------------------------------
-- Q1 JOIN ... ON: operational item and fulfillment detail.
SELECT * FROM v_order_details ORDER BY order_id,sku;
-- Q2 GROUP BY/HAVING: customers placing more than one order.
SELECT c.customer_id,c.full_name,COUNT(o.order_id) AS order_count
FROM customers c JOIN orders o ON o.customer_id=c.customer_id
GROUP BY c.customer_id,c.full_name HAVING COUNT(o.order_id)>=2
ORDER BY order_count DESC,c.customer_id;
-- Q3 scalar subquery: orders whose calculated total exceeds the average.
SELECT order_id,customer_name,order_total FROM v_order_summary
WHERE order_total>(SELECT AVG(order_total) FROM v_order_summary)
ORDER BY order_total DESC,order_id;
-- Q4 FROM-clause subquery: customer totals over THB 1,000.
SELECT c.full_name,x.total_spent FROM customers c JOIN (
 SELECT customer_id,SUM(order_total) AS total_spent FROM v_order_summary
 WHERE order_status<>'CANCELLED' GROUP BY customer_id
) x ON x.customer_id=c.customer_id WHERE x.total_spent>1000
ORDER BY x.total_spent DESC,c.customer_id;
-- Q5 ordered inline Top-N with ROWNUM outside the sort.
SELECT * FROM (SELECT order_id,customer_name,balance_due FROM v_order_summary
 ORDER BY balance_due DESC,order_id) WHERE ROWNUM<=5;
-- Q6 ROLLUP/GROUPING: historical item revenue by category and order status.
SELECT CASE WHEN GROUPING(c.category_name)=1 THEN 'ALL CATEGORIES' ELSE c.category_name END AS category,
 CASE WHEN GROUPING(o.order_status)=1 THEN 'ALL STATUSES' ELSE o.order_status END AS order_status,
 SUM(oi.quantity*oi.unit_price-oi.discount_amount) AS item_revenue,
 GROUPING(c.category_name) AS category_grouped,GROUPING(o.order_status) AS status_grouped
FROM orders o JOIN order_items oi ON oi.order_id=o.order_id
JOIN products p ON p.product_id=oi.product_id JOIN categories c ON c.category_id=p.category_id
GROUP BY ROLLUP(c.category_name,o.order_status)
ORDER BY GROUPING(c.category_name),c.category_name,GROUPING(o.order_status),o.order_status;
-- Q7 correlated subquery: active products never purchased.
SELECT p.product_id,p.product_name FROM products p WHERE p.product_status='ACTIVE'
AND NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id=p.product_id)
ORDER BY p.product_id;
SELECT * FROM v_order_summary ORDER BY order_id;
SELECT * FROM v_top5_customers ORDER BY total_spent DESC,customer_id;

-- 5. DML, SUBQUERY CONDITION, COMMIT / ROLLBACK --------------------
INSERT INTO customers (customer_id,full_name,email) VALUES (900001,'Transaction Demo','transaction@example.com');
COMMIT;
UPDATE customers SET full_name='Uncommitted Name' WHERE customer_id=900001;
ROLLBACK;
SELECT full_name,customer_status FROM customers WHERE customer_id=900001;
DELETE FROM customers c WHERE c.customer_id=900001
AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id);
COMMIT;
SAVEPOINT before_price_demo;
UPDATE products SET list_price=list_price*1.05 WHERE category_id IN (
 SELECT category_id FROM categories WHERE active_flag='Y'
);
SELECT product_name,list_price FROM products ORDER BY product_id;
ROLLBACK TO before_price_demo;
COMMIT;

-- 6. ROLLBACK-SAFE CONSTRAINT TESTS --------------------------------
-- Expected Oracle SQLCODEs are checked; unexpected errors are re-raised.
DECLARE
 PROCEDURE expect_error(p_label VARCHAR2,p_sql VARCHAR2,p_expected NUMBER) IS v_code NUMBER;
 BEGIN
  SAVEPOINT test_case;
  BEGIN EXECUTE IMMEDIATE p_sql;
  EXCEPTION WHEN OTHERS THEN
   v_code:=SQLCODE; ROLLBACK TO test_case;
   IF v_code=p_expected THEN DBMS_OUTPUT.PUT_LINE('PASS: '||p_label||' (SQLCODE '||v_code||')'); RETURN; END IF;
   RAISE;
  END;
  ROLLBACK TO test_case; RAISE_APPLICATION_ERROR(-20001,'FAIL: '||p_label||' unexpectedly succeeded');
 END;
BEGIN
 expect_error('Duplicate customer primary key',q'[INSERT INTO customers VALUES (1,'Test','unique-test@example.com',NULL,'ACTIVE',DATE '2026-01-01')]',-1);
 expect_error('Unique customer email',q'[INSERT INTO customers VALUES (900002,'Test','anan@example.com',NULL,'ACTIVE',DATE '2026-01-01')]',-1);
 expect_error('NOT NULL customer name',q'[INSERT INTO customers VALUES (900002,NULL,'null-test@example.com',NULL,'ACTIVE',DATE '2026-01-01')]',-1400);
 expect_error('Product category foreign key',q'[INSERT INTO products VALUES (900002,999999,'TEST-001','Test',1,0,'ACTIVE')]',-2291);
 expect_error('Positive product price',q'[UPDATE products SET list_price=0 WHERE product_id=1]',-2290);
 expect_error('Positive item quantity',q'[UPDATE order_items SET quantity=0 WHERE order_id=1 AND product_id=1]',-2290);
 expect_error('Shipment delivery chronology',q'[UPDATE shipments SET delivered_on=DATE '2026-01-01' WHERE shipment_id=1]',-2290);
 expect_error('One shipment per order',q'[INSERT INTO shipments VALUES (900002,1,1,'TESTTRACK',NULL,NULL,'PENDING')]',-1);
 expect_error('Review rating range',q'[UPDATE reviews SET rating=6 WHERE review_id=1]',-2290);
 expect_error('Payment protects order history',q'[DELETE FROM orders WHERE order_id=1]',-2292);
END;
/
DECLARE
 v_count NUMBER;
BEGIN
 SAVEPOINT actions_test;
 INSERT INTO carriers VALUES (900003,'Temporary Carrier','TMP','000');
 INSERT INTO customers VALUES (900003,'Temporary Customer','temp-customer@example.com',NULL,'ACTIVE',DATE '2026-03-01');
 INSERT INTO addresses VALUES (900003,900003,'HOME','Temporary Customer','1 Test Lane','Test District','Bangkok','10100','Thailand');
 INSERT INTO orders VALUES (900003,900003,900003,DATE '2026-03-01','NEW',0,0);
 INSERT INTO order_items VALUES (900003,1,1,590,0);
 INSERT INTO shipments VALUES (900003,900003,900003,'TMP-0001',NULL,NULL,'PENDING');
 DELETE FROM carriers WHERE carrier_id=900003;
 SELECT COUNT(*) INTO v_count FROM shipments WHERE shipment_id=900003 AND carrier_id IS NULL;
 IF v_count<>1 THEN RAISE_APPLICATION_ERROR(-20002,'SET NULL failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE SET NULL');
 DELETE FROM orders WHERE order_id=900003;
 SELECT COUNT(*) INTO v_count FROM order_items WHERE order_id=900003;
 IF v_count<>0 THEN RAISE_APPLICATION_ERROR(-20003,'CASCADE failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE CASCADE for order_items');
 ROLLBACK TO actions_test;
EXCEPTION WHEN OTHERS THEN ROLLBACK TO actions_test; RAISE;
END;
/
COMMIT;

-- 7. DATA AUDIT -----------------------------------------------------
-- Expected rows: 10,10,5,10,10,12,10,5,10,10 respectively.
SELECT 'CUSTOMERS' table_name,COUNT(*) row_count FROM customers UNION ALL
SELECT 'ADDRESSES',COUNT(*) FROM addresses UNION ALL SELECT 'CATEGORIES',COUNT(*) FROM categories UNION ALL
SELECT 'PRODUCTS',COUNT(*) FROM products UNION ALL SELECT 'ORDERS',COUNT(*) FROM orders UNION ALL
SELECT 'ORDER_ITEMS',COUNT(*) FROM order_items UNION ALL SELECT 'SHIPMENTS',COUNT(*) FROM shipments UNION ALL
SELECT 'CARRIERS',COUNT(*) FROM carriers UNION ALL SELECT 'PAYMENTS',COUNT(*) FROM payments UNION ALL
SELECT 'REVIEWS',COUNT(*) FROM reviews;
-- Diagnostics expected to return zero rows on seed data.
SELECT o.order_id FROM orders o JOIN addresses a ON a.address_id=o.shipping_address_id WHERE a.customer_id<>o.customer_id;
SELECT oi.order_id,oi.product_id FROM order_items oi JOIN products p ON p.product_id=oi.product_id WHERE oi.quantity>p.stock_qty;
SELECT payment_id,order_id FROM payments WHERE payment_status='CAPTURED' AND amount<=0;
SELECT review_id FROM reviews WHERE LENGTH(TRIM(review_text))=0;

-- 8. OPTIONAL SECURITY (FALSE for hosted APEX) ---------------------
DECLARE
 c_enable_security CONSTANT BOOLEAN := FALSE;
BEGIN
 IF c_enable_security THEN
  EXECUTE IMMEDIATE 'CREATE ROLE ec_sales'; EXECUTE IMMEDIATE 'CREATE ROLE ec_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON customers TO ec_sales';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON addresses TO ec_sales';
  EXECUTE IMMEDIATE 'GRANT SELECT ON products TO ec_sales'; EXECUTE IMMEDIATE 'GRANT SELECT ON categories TO ec_sales';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON orders TO ec_sales'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON order_items TO ec_sales';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_order_details TO ec_sales'; EXECUTE IMMEDIATE 'GRANT SELECT ON v_order_summary TO ec_sales';
  EXECUTE IMMEDIATE 'GRANT ec_sales TO ec_manager'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON products TO ec_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON shipments TO ec_manager'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON payments TO ec_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO ec_manager'; EXECUTE IMMEDIATE 'GRANT SELECT ON v_top5_customers TO ec_manager';
  DBMS_OUTPUT.PUT_LINE('Security roles created; DBA must assign them to database users.');
 ELSE DBMS_OUTPUT.PUT_LINE('NOT RUN: optional CREATE ROLE / GRANT section; requires DBA approval.'); END IF;
END;
/
SELECT table_name,constraint_name,constraint_type,status FROM user_constraints
WHERE table_name IN ('CUSTOMERS','ADDRESSES','CATEGORIES','PRODUCTS','ORDERS','ORDER_ITEMS','SHIPMENTS','CARRIERS','PAYMENTS','REVIEWS')
ORDER BY table_name,constraint_type,constraint_name;
SELECT object_name,status FROM user_objects WHERE object_name IN ('V_ORDER_DETAILS','V_ORDER_SUMMARY','V_TOP5_CUSTOMERS');
-- END OF SCRIPT
