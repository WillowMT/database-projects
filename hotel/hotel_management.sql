/* HOTEL MANAGEMENT SYSTEM -- Oracle 19c+ / APEX SQL Workshop
   Run once in a FRESH schema using SQL Workshop > SQL Scripts.
   No application code. Currency: THB. Fictional sample data.
   Not executed against Oracle by the authoring assistant.
   Oracle DDL commits implicitly; do not rerun over existing objects.
   Model: 10 tables, optional 1:1 reservation/invoice, M:N bookings/rooms.
   Historical booked rates are facts, not copies of current list prices.
   Amounts are computed in views to avoid redundant invoice totals.
   Limits: no tax/refunds; cross-row booking overlap, capacity, payment
   limits and lifecycle rules need production transaction-safe procedures.
   APEX application and MySQL Workbench design are outside this deliverable.
*/

-- 1. TABLES AND CONSTRAINTS -----------------------------------------
CREATE TABLE guests (
 guest_id NUMBER(6) CONSTRAINT pk_guests PRIMARY KEY,
 full_name VARCHAR2(100) NOT NULL,
 email VARCHAR2(120) NOT NULL CONSTRAINT uq_guest_email UNIQUE,
 phone VARCHAR2(25),
 country VARCHAR2(60) DEFAULT 'Thailand' NOT NULL
);
CREATE TABLE room_types (
 room_type_id NUMBER(6) CONSTRAINT pk_room_types PRIMARY KEY,
 type_name VARCHAR2(40) NOT NULL CONSTRAINT uq_type_name UNIQUE,
 capacity NUMBER(2) NOT NULL CONSTRAINT ck_capacity CHECK (capacity BETWEEN 1 AND 10),
 standard_rate NUMBER(10,2) NOT NULL CONSTRAINT ck_standard_rate CHECK (standard_rate > 0)
);
CREATE TABLE rooms (
 room_id NUMBER(6) CONSTRAINT pk_rooms PRIMARY KEY,
 room_number VARCHAR2(10) NOT NULL CONSTRAINT uq_room_number UNIQUE,
 room_type_id NUMBER(6) NOT NULL CONSTRAINT fk_room_type REFERENCES room_types(room_type_id),
 room_status VARCHAR2(15) DEFAULT 'AVAILABLE' NOT NULL,
 CONSTRAINT ck_room_status CHECK (room_status IN ('AVAILABLE','MAINTENANCE'))
);
CREATE TABLE employees (
 employee_id NUMBER(6) CONSTRAINT pk_employees PRIMARY KEY,
 full_name VARCHAR2(100) NOT NULL,
 email VARCHAR2(120) NOT NULL CONSTRAINT uq_employee_email UNIQUE,
 job_title VARCHAR2(50) NOT NULL
);
CREATE TABLE reservations (
 reservation_id NUMBER(6) CONSTRAINT pk_reservations PRIMARY KEY,
 guest_id NUMBER(6) NOT NULL CONSTRAINT fk_res_guest REFERENCES guests(guest_id),
 employee_id NUMBER(6) CONSTRAINT fk_res_employee REFERENCES employees(employee_id) ON DELETE SET NULL,
 booked_on DATE DEFAULT SYSDATE NOT NULL,
 check_in DATE NOT NULL,
 check_out DATE NOT NULL,
 reservation_status VARCHAR2(15) DEFAULT 'CONFIRMED' NOT NULL,
 CONSTRAINT ck_res_dates CHECK (check_out > check_in),
 CONSTRAINT ck_res_midnight CHECK (check_in = TRUNC(check_in) AND check_out = TRUNC(check_out)),
 CONSTRAINT ck_booked_date CHECK (TRUNC(booked_on) <= check_in),
 CONSTRAINT ck_res_status CHECK (reservation_status IN ('CONFIRMED','CHECKED_IN','CHECKED_OUT','CANCELLED'))
);
CREATE TABLE reservation_rooms (
 reservation_id NUMBER(6) CONSTRAINT fk_rr_res REFERENCES reservations(reservation_id) ON DELETE CASCADE,
 room_id NUMBER(6) CONSTRAINT fk_rr_room REFERENCES rooms(room_id),
 nightly_rate NUMBER(10,2) NOT NULL CONSTRAINT ck_nightly_rate CHECK (nightly_rate > 0),
 occupants NUMBER(2) DEFAULT 1 NOT NULL CONSTRAINT ck_occupants CHECK (occupants BETWEEN 1 AND 10),
 CONSTRAINT pk_reservation_rooms PRIMARY KEY (reservation_id, room_id)
);
CREATE TABLE services (
 service_id NUMBER(6) CONSTRAINT pk_services PRIMARY KEY,
 service_name VARCHAR2(60) NOT NULL CONSTRAINT uq_service_name UNIQUE,
 list_price NUMBER(10,2) NOT NULL CONSTRAINT ck_list_price CHECK (list_price > 0)
);
CREATE TABLE service_charges (
 charge_id NUMBER(6) CONSTRAINT pk_service_charges PRIMARY KEY,
 reservation_id NUMBER(6) NOT NULL CONSTRAINT fk_charge_res REFERENCES reservations(reservation_id) ON DELETE CASCADE,
 service_id NUMBER(6) NOT NULL CONSTRAINT fk_charge_service REFERENCES services(service_id),
 charged_on DATE NOT NULL,
 quantity NUMBER(4) DEFAULT 1 NOT NULL CONSTRAINT ck_quantity CHECK (quantity > 0),
 unit_price NUMBER(10,2) NOT NULL CONSTRAINT ck_unit_price CHECK (unit_price > 0)
);
CREATE TABLE invoices (
 invoice_id NUMBER(6) CONSTRAINT pk_invoices PRIMARY KEY,
 reservation_id NUMBER(6) NOT NULL CONSTRAINT uq_invoice_res UNIQUE,
 issued_on DATE DEFAULT SYSDATE NOT NULL,
 due_on DATE NOT NULL,
 CONSTRAINT fk_invoice_res FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
 CONSTRAINT ck_invoice_dates CHECK (due_on >= issued_on)
);
CREATE TABLE payments (
 payment_id NUMBER(6) CONSTRAINT pk_payments PRIMARY KEY,
 invoice_id NUMBER(6) NOT NULL CONSTRAINT fk_payment_invoice REFERENCES invoices(invoice_id),
 paid_on DATE DEFAULT SYSDATE NOT NULL,
 amount NUMBER(10,2) NOT NULL CONSTRAINT ck_payment_amount CHECK (amount > 0),
 payment_method VARCHAR2(15) NOT NULL,
 payment_reference VARCHAR2(60) NOT NULL CONSTRAINT uq_payment_ref UNIQUE,
 CONSTRAINT ck_payment_method CHECK (payment_method IN ('CASH','CARD','TRANSFER'))
);

-- CASCADE removes dependent details of an uninvoiced reservation.
-- SET NULL preserves a reservation when its staff record is removed.
-- Financial history is protected by restrictive invoice/payment FKs.

-- 2. MASTER DATA ---------------------------------------------------
INSERT ALL
 INTO guests VALUES (1,'Anan Suri','anan@example.com','0811111001','Thailand')
 INTO guests VALUES (2,'Maya Chen','maya@example.com','0811111002','Singapore')
 INTO guests VALUES (3,'James Wilson','james@example.com','0811111003','United Kingdom')
 INTO guests VALUES (4,'Sofia Rossi','sofia@example.com','0811111004','Italy')
 INTO guests VALUES (5,'Min Thu','min@example.com','0811111005','Myanmar')
 INTO guests VALUES (6,'Yuki Sato','yuki@example.com','0811111006','Japan')
 INTO guests VALUES (7,'Lina Park','lina@example.com','0811111007','South Korea')
 INTO guests VALUES (8,'Noah Brown','noah@example.com','0811111008','Australia')
 INTO guests VALUES (9,'Emma Martin','emma@example.com','0811111009','France')
 INTO guests VALUES (10,'Niran Chai','niran@example.com','0811111010','Thailand')
SELECT 1 FROM dual;
INSERT ALL
 INTO room_types VALUES (1,'Standard',2,1500)
 INTO room_types VALUES (2,'Deluxe',2,2200)
 INTO room_types VALUES (3,'Twin',2,2000)
 INTO room_types VALUES (4,'Family',4,3500)
 INTO room_types VALUES (5,'Suite',4,5000)
SELECT 1 FROM dual;
INSERT ALL
 INTO rooms VALUES (1,'101',1,'AVAILABLE')
 INTO rooms VALUES (2,'102',1,'AVAILABLE')
 INTO rooms VALUES (3,'201',2,'AVAILABLE')
 INTO rooms VALUES (4,'202',2,'AVAILABLE')
 INTO rooms VALUES (5,'301',3,'AVAILABLE')
 INTO rooms VALUES (6,'302',3,'AVAILABLE')
 INTO rooms VALUES (7,'401',4,'AVAILABLE')
 INTO rooms VALUES (8,'402',4,'AVAILABLE')
 INTO rooms VALUES (9,'501',5,'AVAILABLE')
 INTO rooms VALUES (10,'502',5,'AVAILABLE')
SELECT 1 FROM dual;
INSERT ALL
 INTO employees VALUES (1,'Pim Arun','pim@hotel.example','Receptionist')
 INTO employees VALUES (2,'Somchai Dee','somchai@hotel.example','Receptionist')
 INTO employees VALUES (3,'Nok Suda','nok@hotel.example','Front Office Supervisor')
 INTO employees VALUES (4,'Kanya Lek','kanya@hotel.example','Reservations Officer')
 INTO employees VALUES (5,'Arun Wichai','arun@hotel.example','Hotel Manager')
SELECT 1 FROM dual;
INSERT ALL
 INTO services VALUES (1,'Breakfast',300)
 INTO services VALUES (2,'Laundry',150)
 INTO services VALUES (3,'Airport Transfer',900)
 INTO services VALUES (4,'Spa Treatment',1200)
 INTO services VALUES (5,'Room Service',450)
SELECT 1 FROM dual;

-- 12 stays: spaced four days apart, each lasting two nights.
-- Includes repeat guests and repeat rooms without overlapping bookings.
-- Each transaction/detail table receives at least 12 records.
DECLARE
 v_room NUMBER; v_service NUMBER; v_rate NUMBER; v_price NUMBER;
 v_arrival DATE;
BEGIN
 FOR i IN 1..12 LOOP
  v_room := MOD(i-1,10)+1;
  v_service := MOD(i-1,5)+1;
  v_arrival := DATE '2026-01-01' + (i-1)*4;
  SELECT t.standard_rate INTO v_rate FROM rooms r
   JOIN room_types t ON t.room_type_id=r.room_type_id WHERE r.room_id=v_room;
  SELECT list_price INTO v_price FROM services WHERE service_id=v_service;
  INSERT INTO reservations VALUES
   (i,MOD(i-1,10)+1,MOD(i-1,5)+1,v_arrival-10,v_arrival,v_arrival+2,'CHECKED_OUT');
  INSERT INTO reservation_rooms VALUES (i,v_room,v_rate,2);
  INSERT INTO service_charges VALUES (i,i,v_service,v_arrival+1,1,v_price);
  INSERT INTO invoices VALUES (i,i,v_arrival+2,v_arrival+9);
  INSERT INTO payments VALUES (i,i,v_arrival+2,1000,'CARD','PAY-'||TO_CHAR(i,'FM000'));
 END LOOP;
 -- Two bookings contain two rooms, demonstrating the junction table.
 INSERT INTO reservation_rooms VALUES (1,2,1500,1);
 INSERT INTO reservation_rooms VALUES (3,4,2200,1);
END;
/
COMMIT;

-- 3. VIEWS ---------------------------------------------------------
-- V1: Multi-table operational view; one row per reserved room.
CREATE OR REPLACE VIEW v_booking_details AS
SELECT r.reservation_id, g.full_name AS guest_name,
       e.full_name AS employee_name, rm.room_number, t.type_name,
       r.check_in, r.check_out, r.reservation_status,
       rr.occupants, rr.nightly_rate,
       (r.check_out-r.check_in)*rr.nightly_rate AS room_total
FROM reservations r
JOIN guests g ON g.guest_id=r.guest_id
LEFT JOIN employees e ON e.employee_id=r.employee_id
JOIN reservation_rooms rr ON rr.reservation_id=r.reservation_id
JOIN rooms rm ON rm.room_id=rr.room_id
JOIN room_types t ON t.room_type_id=rm.room_type_id;

-- V2: Aggregate invoice summary. Preaggregate each child independently
-- so multiple rooms, charges and payments cannot multiply the totals.
CREATE OR REPLACE VIEW v_invoice_summary AS
SELECT i.invoice_id, i.reservation_id, g.full_name AS guest_name,
       i.issued_on, i.due_on,
       NVL(rm.room_total,0) AS room_total,
       NVL(sc.service_total,0) AS service_total,
       NVL(rm.room_total,0)+NVL(sc.service_total,0) AS invoice_total,
       NVL(p.paid_total,0) AS paid_total,
       NVL(rm.room_total,0)+NVL(sc.service_total,0)-NVL(p.paid_total,0) AS balance_due
FROM invoices i
JOIN reservations r ON r.reservation_id=i.reservation_id
JOIN guests g ON g.guest_id=r.guest_id
LEFT JOIN (
 SELECT rr.reservation_id,
        SUM(rr.nightly_rate*(r.check_out-r.check_in)) AS room_total
 FROM reservation_rooms rr
 JOIN reservations r ON r.reservation_id=rr.reservation_id
 GROUP BY rr.reservation_id
) rm ON rm.reservation_id=i.reservation_id
LEFT JOIN (
 SELECT reservation_id,SUM(quantity*unit_price) AS service_total
 FROM service_charges GROUP BY reservation_id
) sc ON sc.reservation_id=i.reservation_id
LEFT JOIN (
 SELECT invoice_id,SUM(amount) AS paid_total
 FROM payments GROUP BY invoice_id
) p ON p.invoice_id=i.invoice_id;

-- V3: Restricted projection + Top-N; intentionally excludes contact data.
CREATE OR REPLACE VIEW v_top5_guests AS
SELECT guest_id, full_name, total_billed
FROM (
 SELECT g.guest_id,g.full_name,SUM(s.invoice_total) AS total_billed
 FROM guests g
 JOIN reservations r ON r.guest_id=g.guest_id
 JOIN v_invoice_summary s ON s.reservation_id=r.reservation_id
 GROUP BY g.guest_id,g.full_name
 ORDER BY total_billed DESC,g.guest_id
)
WHERE ROWNUM <= 5;

-- 4. REQUIRED QUERIES ----------------------------------------------
-- Q1: JOIN ... ON. Room assignments and historical room charges.
SELECT * FROM v_booking_details ORDER BY reservation_id,room_number;

-- Q2: GROUP BY / HAVING across related tables. Repeat guests.
SELECT g.guest_id,g.full_name,COUNT(r.reservation_id) AS booking_count
FROM guests g JOIN reservations r ON r.guest_id=g.guest_id
GROUP BY g.guest_id,g.full_name
HAVING COUNT(r.reservation_id)>=2
ORDER BY booking_count DESC,g.guest_id;

-- Q3: Scalar subquery. Invoices above the average invoice value.
SELECT invoice_id,guest_name,invoice_total
FROM v_invoice_summary
WHERE invoice_total > (SELECT AVG(invoice_total) FROM v_invoice_summary)
ORDER BY invoice_total DESC,invoice_id;

-- Q4: FROM-clause subquery. Guests with cumulative billing over THB 5,000.
SELECT g.full_name,x.total_billed
FROM guests g
JOIN (
 SELECT r.guest_id,SUM(s.invoice_total) AS total_billed
 FROM reservations r JOIN v_invoice_summary s
 ON s.reservation_id=r.reservation_id
 GROUP BY r.guest_id
) x ON x.guest_id=g.guest_id
WHERE x.total_billed>5000
ORDER BY x.total_billed DESC,g.guest_id;

-- Q5: Top-N uses sorting INSIDE the inline view, ROWNUM OUTSIDE.
SELECT * FROM (
 SELECT invoice_id,guest_name,balance_due FROM v_invoice_summary
 ORDER BY balance_due DESC,invoice_id
) WHERE ROWNUM<=5;

-- Q6: ROLLUP and GROUPING distinguish detail, subtotals and grand total.
SELECT CASE WHEN GROUPING(t.type_name)=1 THEN 'ALL ROOM TYPES'
            ELSE t.type_name END AS room_type,
       CASE WHEN GROUPING(r.reservation_status)=1 THEN 'ALL STATUSES'
            ELSE r.reservation_status END AS booking_status,
       SUM((r.check_out-r.check_in)*rr.nightly_rate) AS room_revenue,
       GROUPING(t.type_name) AS type_grouped,
       GROUPING(r.reservation_status) AS status_grouped
FROM reservations r
JOIN reservation_rooms rr ON rr.reservation_id=r.reservation_id
JOIN rooms rm ON rm.room_id=rr.room_id
JOIN room_types t ON t.room_type_id=rm.room_type_id
WHERE r.reservation_status<>'CANCELLED'
GROUP BY ROLLUP(t.type_name,r.reservation_status)
ORDER BY GROUPING(t.type_name),t.type_name,
         GROUPING(r.reservation_status),r.reservation_status;

-- Q7: Correlated NOT EXISTS. Available rooms for a proposed date range.
-- Intervals are [check_in, check_out); same-day turnover is allowed.
SELECT rm.room_number,t.type_name,t.standard_rate
FROM rooms rm JOIN room_types t ON t.room_type_id=rm.room_type_id
WHERE rm.room_status='AVAILABLE'
AND NOT EXISTS (
 SELECT 1 FROM reservation_rooms rr
 JOIN reservations r ON r.reservation_id=rr.reservation_id
 WHERE rr.room_id=rm.room_id AND r.reservation_status<>'CANCELLED'
 AND r.check_in<DATE '2026-01-03' AND r.check_out>DATE '2026-01-01'
)
ORDER BY rm.room_number;

-- 5. DML, CONDITIONAL SUBQUERY, COMMIT AND ROLLBACK ------------------
-- Commit a temporary guest, then undo an UPDATE, then delete the guest.
INSERT INTO guests (guest_id,full_name,email)
VALUES (900001,'Transaction Demo','transaction@example.com');
COMMIT;
UPDATE guests SET full_name='Uncommitted Name' WHERE guest_id=900001;
ROLLBACK;
-- Expected: Transaction Demo; country Thailand (DEFAULT demonstration).
SELECT full_name,country FROM guests WHERE guest_id=900001;

-- Conditional DELETE: only remove the guest if no reservation exists.
DELETE FROM guests g WHERE g.guest_id=900001
AND NOT EXISTS (SELECT 1 FROM reservations r WHERE r.guest_id=g.guest_id);
COMMIT;

-- 6. AUTOMATED CONSTRAINT TESTS ------------------------------------
-- Every attempted change is rolled back. Unexpected errors are re-raised.
DECLARE
 PROCEDURE expect_error(p_label VARCHAR2,p_sql VARCHAR2,p_expected NUMBER) IS
  v_code NUMBER;
 BEGIN
  SAVEPOINT test_case;
  BEGIN
   EXECUTE IMMEDIATE p_sql;
  EXCEPTION WHEN OTHERS THEN
   v_code:=SQLCODE;
   ROLLBACK TO test_case;
   IF v_code=p_expected THEN
    DBMS_OUTPUT.PUT_LINE('PASS: '||p_label||' (SQLCODE '||v_code||')');
    RETURN;
   END IF;
   RAISE;
  END;
  ROLLBACK TO test_case;
  RAISE_APPLICATION_ERROR(-20001,'FAIL: '||p_label||' unexpectedly succeeded');
 END;
BEGIN
 expect_error('Duplicate primary key',
  q'[INSERT INTO guests VALUES (1,'Test','unique-test@example.com',NULL,'Thailand')]',-1);
 expect_error('Unique guest email',
  q'[INSERT INTO guests VALUES (900002,'Test','anan@example.com',NULL,'Thailand')]',-1);
 expect_error('NOT NULL guest name',
  q'[INSERT INTO guests VALUES (900002,NULL,'null-test@example.com',NULL,'Thailand')]',-1400);
 expect_error('Room type foreign key',
  q'[INSERT INTO rooms VALUES (900002,'TEST',999999,'AVAILABLE')]',-2291);
 expect_error('Positive room rate',
  q'[UPDATE room_types SET standard_rate=-1 WHERE room_type_id=1]',-2290);
 expect_error('Valid reservation date range',
  q'[UPDATE reservations SET check_out=check_in WHERE reservation_id=1]',-2290);
 expect_error('Positive payment amount',
  q'[UPDATE payments SET amount=0 WHERE payment_id=1]',-2290);
 expect_error('One invoice per reservation',
  q'[INSERT INTO invoices VALUES (900002,1,DATE '2026-01-03',DATE '2026-01-10')]',-1);
 expect_error('Invoice protects reservation history',
  q'[DELETE FROM reservations WHERE reservation_id=1]',-2292);
END;
/

-- Test both referential actions without permanently changing sample data.
DECLARE
 v_count NUMBER;
BEGIN
 SAVEPOINT actions_test;
 INSERT INTO employees VALUES (900003,'Temporary Staff','temp@hotel.example','Receptionist');
 INSERT INTO reservations VALUES
  (900003,1,900003,DATE '2026-03-01',DATE '2026-03-10',DATE '2026-03-12','CONFIRMED');
 INSERT INTO reservation_rooms VALUES (900003,1,1500,1);
 INSERT INTO service_charges VALUES (900003,900003,1,DATE '2026-03-11',1,300);
 DELETE FROM employees WHERE employee_id=900003;
 SELECT COUNT(*) INTO v_count FROM reservations
 WHERE reservation_id=900003 AND employee_id IS NULL;
 IF v_count<>1 THEN RAISE_APPLICATION_ERROR(-20002,'SET NULL failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE SET NULL');
 DELETE FROM reservations WHERE reservation_id=900003;
 SELECT (SELECT COUNT(*) FROM reservation_rooms WHERE reservation_id=900003)
       +(SELECT COUNT(*) FROM service_charges WHERE reservation_id=900003)
 INTO v_count FROM dual;
 IF v_count<>0 THEN RAISE_APPLICATION_ERROR(-20003,'CASCADE failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE CASCADE for both detail tables');
 ROLLBACK TO actions_test;
EXCEPTION WHEN OTHERS THEN
 ROLLBACK TO actions_test;
 RAISE;
END;
/
COMMIT;

-- 7. SECURITY: OPTIONAL DBA-ENABLED SECTION -------------------------
-- Hosted APEX schemas commonly lack CREATE ROLE. Leave FALSE there.
-- On a dedicated database, use fresh role names and set TRUE if allowed.
-- Role creation and GRANT are DDL; failures may leave a partial setup.
-- No grant to PUBLIC; reception has no payment-write privileges.
-- APEX end-user authorization is separate from database roles.
DECLARE
 c_enable_security CONSTANT BOOLEAN := FALSE;
BEGIN
 IF c_enable_security THEN
  EXECUTE IMMEDIATE 'CREATE ROLE hm_reception';
  EXECUTE IMMEDIATE 'CREATE ROLE hm_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON guests TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON rooms TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON room_types TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON services TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON reservations TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON reservation_rooms TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_booking_details TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_invoice_summary TO hm_reception';
  EXECUTE IMMEDIATE 'GRANT hm_reception TO hm_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON services TO hm_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON service_charges TO hm_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON invoices TO hm_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON payments TO hm_manager';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_top5_guests TO hm_manager';
  DBMS_OUTPUT.PUT_LINE('Security roles created; DBA must assign them to actual database users.');
 ELSE
  DBMS_OUTPUT.PUT_LINE('NOT RUN: optional CREATE ROLE / GRANT section; requires DBA approval.');
 END IF;
END;
/
-- DBA assignment examples (replace usernames; do not use APEX login names):
-- GRANT hm_reception TO actual_reception_database_user;
-- GRANT hm_manager TO actual_manager_database_user;

-- END OF SCRIPT
