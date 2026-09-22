/* LOGISTICS / FLEET MANAGEMENT -- Oracle Database 19c+ / APEX SQL Workshop
   Run once in a FRESH schema. No DROP statements: Oracle DDL commits implicitly.
   Fictional data, THB charges. No Oracle runtime was available during authoring.
   Exactly 10 tables. Shipment charge is stored once on SHIPMENTS, never per trip leg.
*/

-- 1. TABLES AND CONSTRAINTS -----------------------------------------
CREATE TABLE customers (
 customer_id NUMBER(6) CONSTRAINT pk_customers PRIMARY KEY,
 customer_name VARCHAR2(100) NOT NULL,
 contact_email VARCHAR2(120) NOT NULL CONSTRAINT uq_customer_email UNIQUE,
 contact_phone VARCHAR2(25),
 customer_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_customer_status CHECK (customer_status IN ('ACTIVE','SUSPENDED'))
);
CREATE TABLE depots (
 depot_id NUMBER(6) CONSTRAINT pk_depots PRIMARY KEY,
 depot_code VARCHAR2(10) NOT NULL CONSTRAINT uq_depot_code UNIQUE,
 depot_name VARCHAR2(100) NOT NULL,
 province VARCHAR2(60) NOT NULL,
 latitude NUMBER(8,5) NOT NULL,
 longitude NUMBER(8,5) NOT NULL,
 depot_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_depot_lat CHECK (latitude BETWEEN -90 AND 90),
 CONSTRAINT ck_depot_lon CHECK (longitude BETWEEN -180 AND 180),
 CONSTRAINT ck_depot_status CHECK (depot_status IN ('ACTIVE','INACTIVE'))
);
CREATE TABLE drivers (
 driver_id NUMBER(6) CONSTRAINT pk_drivers PRIMARY KEY,
 full_name VARCHAR2(100) NOT NULL,
 license_no VARCHAR2(30) NOT NULL CONSTRAINT uq_driver_license UNIQUE,
 license_expiry DATE NOT NULL,
 phone VARCHAR2(25) NOT NULL CONSTRAINT uq_driver_phone UNIQUE,
 driver_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_driver_status CHECK (driver_status IN ('ACTIVE','INACTIVE','ON_LEAVE'))
);
CREATE TABLE vehicles (
 vehicle_id NUMBER(6) CONSTRAINT pk_vehicles PRIMARY KEY,
 registration_no VARCHAR2(20) NOT NULL CONSTRAINT uq_vehicle_registration UNIQUE,
 vehicle_type VARCHAR2(20) NOT NULL,
 capacity_kg NUMBER(9,2) NOT NULL,
 vehicle_status VARCHAR2(15) DEFAULT 'AVAILABLE' NOT NULL,
 current_depot_id NUMBER(6) CONSTRAINT fk_vehicle_depot REFERENCES depots(depot_id) ON DELETE SET NULL,
 CONSTRAINT ck_vehicle_type CHECK (vehicle_type IN ('VAN','TRUCK','REEFER')),
 CONSTRAINT ck_vehicle_capacity CHECK (capacity_kg > 0),
 CONSTRAINT ck_vehicle_status CHECK (vehicle_status IN ('AVAILABLE','IN_TRANSIT','MAINTENANCE'))
);
CREATE TABLE shipments (
 shipment_id NUMBER(6) CONSTRAINT pk_shipments PRIMARY KEY,
 shipment_no VARCHAR2(20) NOT NULL CONSTRAINT uq_shipment_no UNIQUE,
 customer_id NUMBER(6) NOT NULL CONSTRAINT fk_shipment_customer REFERENCES customers(customer_id),
 origin_depot_id NUMBER(6) NOT NULL CONSTRAINT fk_shipment_origin REFERENCES depots(depot_id),
 destination_depot_id NUMBER(6) NOT NULL CONSTRAINT fk_shipment_destination REFERENCES depots(depot_id),
 booked_on DATE DEFAULT SYSDATE NOT NULL,
 promised_date DATE NOT NULL,
 weight_kg NUMBER(9,2) NOT NULL,
 freight_charge NUMBER(10,2) NOT NULL,
 shipment_status VARCHAR2(16) DEFAULT 'BOOKED' NOT NULL,
 CONSTRAINT ck_shipment_depots CHECK (origin_depot_id <> destination_depot_id),
 CONSTRAINT ck_shipment_dates CHECK (TRUNC(promised_date) >= TRUNC(booked_on)),
 CONSTRAINT ck_shipment_weight CHECK (weight_kg > 0),
 CONSTRAINT ck_shipment_charge CHECK (freight_charge > 0),
 CONSTRAINT ck_shipment_status CHECK (shipment_status IN ('BOOKED','IN_TRANSIT','DELIVERED','CANCELLED'))
);
CREATE TABLE shipment_tracking (
 tracking_id NUMBER(6) CONSTRAINT pk_shipment_tracking PRIMARY KEY,
 shipment_id NUMBER(6) NOT NULL CONSTRAINT fk_tracking_shipment REFERENCES shipments(shipment_id) ON DELETE CASCADE,
 event_time DATE NOT NULL,
 event_status VARCHAR2(20) NOT NULL,
 event_depot_id NUMBER(6) CONSTRAINT fk_tracking_depot REFERENCES depots(depot_id) ON DELETE SET NULL,
 event_note VARCHAR2(200),
 CONSTRAINT uq_tracking_event UNIQUE (shipment_id,event_time,event_status),
 CONSTRAINT ck_tracking_status CHECK (event_status IN ('BOOKED','PICKED_UP','ARRIVED_DEPOT','DEPARTED_DEPOT','OUT_FOR_DELIVERY','DELIVERED','EXCEPTION'))
);
CREATE TABLE delivery_receipts (
 shipment_id NUMBER(6) CONSTRAINT pk_delivery_receipts PRIMARY KEY,
 received_by VARCHAR2(100) NOT NULL,
 received_on DATE NOT NULL,
 proof_reference VARCHAR2(60) NOT NULL CONSTRAINT uq_receipt_proof UNIQUE,
 receipt_status VARCHAR2(12) DEFAULT 'ACCEPTED' NOT NULL,
 CONSTRAINT fk_receipt_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
 CONSTRAINT ck_receipt_status CHECK (receipt_status IN ('ACCEPTED','DAMAGED','REFUSED'))
);
CREATE TABLE trips (
 trip_id NUMBER(6) CONSTRAINT pk_trips PRIMARY KEY,
 trip_no VARCHAR2(20) NOT NULL CONSTRAINT uq_trip_no UNIQUE,
 vehicle_id NUMBER(6) NOT NULL CONSTRAINT fk_trip_vehicle REFERENCES vehicles(vehicle_id),
 driver_id NUMBER(6) CONSTRAINT fk_trip_driver REFERENCES drivers(driver_id) ON DELETE SET NULL,
 start_depot_id NUMBER(6) NOT NULL CONSTRAINT fk_trip_start_depot REFERENCES depots(depot_id),
 end_depot_id NUMBER(6) NOT NULL CONSTRAINT fk_trip_end_depot REFERENCES depots(depot_id),
 planned_departure DATE NOT NULL,
 planned_arrival DATE NOT NULL,
 trip_status VARCHAR2(15) DEFAULT 'PLANNED' NOT NULL,
 CONSTRAINT ck_trip_depots CHECK (start_depot_id <> end_depot_id),
 CONSTRAINT ck_trip_dates CHECK (planned_arrival > planned_departure),
 CONSTRAINT ck_trip_status CHECK (trip_status IN ('PLANNED','DISPATCHED','COMPLETED','CANCELLED'))
);
CREATE TABLE trip_shipments (
 trip_id NUMBER(6) CONSTRAINT fk_ts_trip REFERENCES trips(trip_id) ON DELETE CASCADE,
 shipment_id NUMBER(6) CONSTRAINT fk_ts_shipment REFERENCES shipments(shipment_id),
 leg_sequence NUMBER(3) NOT NULL,
 loaded_kg NUMBER(9,2) NOT NULL,
 CONSTRAINT pk_trip_shipments PRIMARY KEY (trip_id,shipment_id),
 CONSTRAINT uq_trip_leg UNIQUE (trip_id,leg_sequence),
 CONSTRAINT ck_ts_sequence CHECK (leg_sequence > 0),
 CONSTRAINT ck_ts_loaded CHECK (loaded_kg > 0)
);
CREATE TABLE maintenance_records (
 maintenance_id NUMBER(6) CONSTRAINT pk_maintenance_records PRIMARY KEY,
 vehicle_id NUMBER(6) NOT NULL CONSTRAINT fk_maintenance_vehicle REFERENCES vehicles(vehicle_id),
 maintenance_date DATE NOT NULL,
 maintenance_type VARCHAR2(20) NOT NULL,
 odometer_km NUMBER(10) NOT NULL,
 maintenance_cost NUMBER(10,2) NOT NULL,
 maintenance_status VARCHAR2(12) DEFAULT 'COMPLETED' NOT NULL,
 CONSTRAINT ck_maintenance_type CHECK (maintenance_type IN ('SERVICE','REPAIR','INSPECTION','TYRES')),
 CONSTRAINT ck_maintenance_odometer CHECK (odometer_km >= 0),
 CONSTRAINT ck_maintenance_cost CHECK (maintenance_cost >= 0),
 CONSTRAINT ck_maintenance_status CHECK (maintenance_status IN ('SCHEDULED','COMPLETED'))
);
CREATE INDEX ix_shipment_customer ON shipments(customer_id);
CREATE INDEX ix_shipment_origin ON shipments(origin_depot_id);
CREATE INDEX ix_shipment_destination ON shipments(destination_depot_id);
CREATE INDEX ix_tracking_shipment ON shipment_tracking(shipment_id);
CREATE INDEX ix_trip_vehicle ON trips(vehicle_id);
CREATE INDEX ix_ts_shipment ON trip_shipments(shipment_id);
CREATE INDEX ix_maintenance_vehicle ON maintenance_records(vehicle_id);

-- 2. SEED DATA ------------------------------------------------------
INSERT ALL
 INTO customers VALUES (1,'Siam Retail Co.','ops@siamretail.example','021001001','ACTIVE')
 INTO customers VALUES (2,'Andaman Foods','dispatch@andamanfoods.example','021001002','ACTIVE')
 INTO customers VALUES (3,'Northstar Medical','logistics@northstar.example','021001003','ACTIVE')
 INTO customers VALUES (4,'Mekong Parts','freight@mekongparts.example','021001004','ACTIVE')
 INTO customers VALUES (5,'Eastern Textiles','ship@easterntextiles.example','021001005','ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO depots VALUES (1,'BKK','Bangkok Central Depot','Bangkok',13.75630,100.50180,'ACTIVE')
 INTO depots VALUES (2,'CMA','Chiang Mai Depot','Chiang Mai',18.78830,98.98530,'ACTIVE')
 INTO depots VALUES (3,'KKN','Khon Kaen Depot','Khon Kaen',16.44190,102.83590,'ACTIVE')
 INTO depots VALUES (4,'HKT','Phuket Depot','Phuket',7.88040,98.39230,'ACTIVE')
 INTO depots VALUES (5,'RYG','Rayong Depot','Rayong',12.68100,101.28100,'ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO drivers VALUES (1,'Niran Chai','TH-DL-10001',DATE '2028-05-31','0810001001','ACTIVE')
 INTO drivers VALUES (2,'Mali Sorn','TH-DL-10002',DATE '2027-11-30','0810001002','ACTIVE')
 INTO drivers VALUES (3,'Preecha Wan','TH-DL-10003',DATE '2029-01-31','0810001003','ACTIVE')
 INTO drivers VALUES (4,'Kanda Lek','TH-DL-10004',DATE '2027-08-31','0810001004','ACTIVE')
 INTO drivers VALUES (5,'Somjit Arun','TH-DL-10005',DATE '2028-09-30','0810001005','ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO vehicles VALUES (1,'70-1001 BKK','VAN',1200,'AVAILABLE',1)
 INTO vehicles VALUES (2,'70-1002 BKK','TRUCK',5000,'AVAILABLE',1)
 INTO vehicles VALUES (3,'80-2001 CMA','TRUCK',4000,'AVAILABLE',2)
 INTO vehicles VALUES (4,'83-3001 KKN','REEFER',3000,'AVAILABLE',3)
 INTO vehicles VALUES (5,'81-4001 HKT','VAN',1000,'AVAILABLE',4)
SELECT 1 FROM dual;
INSERT ALL
 INTO shipments VALUES (1,'SHP-2026-001',1,1,2,DATE '2026-01-02',DATE '2026-01-05',400,1800,'DELIVERED')
 INTO shipments VALUES (2,'SHP-2026-002',2,1,3,DATE '2026-01-03',DATE '2026-01-06',850,2600,'DELIVERED')
 INTO shipments VALUES (3,'SHP-2026-003',3,2,1,DATE '2026-01-04',DATE '2026-01-07',300,1700,'DELIVERED')
 INTO shipments VALUES (4,'SHP-2026-004',4,3,1,DATE '2026-01-05',DATE '2026-01-08',1200,3200,'DELIVERED')
 INTO shipments VALUES (5,'SHP-2026-005',5,1,5,DATE '2026-01-06',DATE '2026-01-09',650,2100,'DELIVERED')
 INTO shipments VALUES (6,'SHP-2026-006',1,5,1,DATE '2026-01-07',DATE '2026-01-10',500,2000,'DELIVERED')
 INTO shipments VALUES (7,'SHP-2026-007',2,4,1,DATE '2026-01-08',DATE '2026-01-11',700,2400,'DELIVERED')
 INTO shipments VALUES (8,'SHP-2026-008',3,1,4,DATE '2026-01-09',DATE '2026-01-12',450,2300,'DELIVERED')
 INTO shipments VALUES (9,'SHP-2026-009',4,2,3,DATE '2026-01-10',DATE '2026-01-13',900,2700,'DELIVERED')
 INTO shipments VALUES (10,'SHP-2026-010',5,3,2,DATE '2026-01-11',DATE '2026-01-14',350,1600,'DELIVERED')
 INTO shipments VALUES (11,'SHP-2026-011',1,1,3,DATE '2026-01-12',DATE '2026-01-15',1100,3000,'IN_TRANSIT')
 INTO shipments VALUES (12,'SHP-2026-012',2,4,5,DATE '2026-01-13',DATE '2026-01-16',600,2200,'IN_TRANSIT')
SELECT 1 FROM dual;
INSERT ALL
 INTO trips VALUES (1,'TRP-2026-001',2,1,1,2,DATE '2026-01-02',DATE '2026-01-03','COMPLETED')
 INTO trips VALUES (2,'TRP-2026-002',2,2,1,3,DATE '2026-01-03',DATE '2026-01-04','COMPLETED')
 INTO trips VALUES (3,'TRP-2026-003',3,3,2,1,DATE '2026-01-04',DATE '2026-01-05','COMPLETED')
 INTO trips VALUES (4,'TRP-2026-004',4,4,3,1,DATE '2026-01-05',DATE '2026-01-06','COMPLETED')
 INTO trips VALUES (5,'TRP-2026-005',2,5,1,5,DATE '2026-01-06',DATE '2026-01-07','COMPLETED')
 INTO trips VALUES (6,'TRP-2026-006',2,1,5,1,DATE '2026-01-07',DATE '2026-01-08','COMPLETED')
 INTO trips VALUES (7,'TRP-2026-007',5,2,4,1,DATE '2026-01-08',DATE '2026-01-09','COMPLETED')
 INTO trips VALUES (8,'TRP-2026-008',5,3,1,4,DATE '2026-01-09',DATE '2026-01-10','COMPLETED')
 INTO trips VALUES (9,'TRP-2026-009',3,4,2,3,DATE '2026-01-10',DATE '2026-01-11','COMPLETED')
 INTO trips VALUES (10,'TRP-2026-010',4,5,3,2,DATE '2026-01-11',DATE '2026-01-12','COMPLETED')
SELECT 1 FROM dual;
INSERT ALL
 INTO trip_shipments VALUES (1,1,1,400) INTO trip_shipments VALUES (1,9,2,900)
 INTO trip_shipments VALUES (2,2,1,850) INTO trip_shipments VALUES (2,11,2,1100)
 INTO trip_shipments VALUES (3,3,1,300) INTO trip_shipments VALUES (3,9,2,900)
 INTO trip_shipments VALUES (4,4,1,1200) INTO trip_shipments VALUES (5,5,1,650)
 INTO trip_shipments VALUES (6,6,1,500) INTO trip_shipments VALUES (7,7,1,700)
 INTO trip_shipments VALUES (8,8,1,450) INTO trip_shipments VALUES (9,10,1,350)
 INTO trip_shipments VALUES (9,11,2,1100) INTO trip_shipments VALUES (10,12,1,600)
SELECT 1 FROM dual;
INSERT ALL
 INTO shipment_tracking VALUES (1,1,DATE '2026-01-02','PICKED_UP',1,'Collected at Bangkok')
 INTO shipment_tracking VALUES (2,2,DATE '2026-01-03','PICKED_UP',1,'Collected at Bangkok')
 INTO shipment_tracking VALUES (3,3,DATE '2026-01-04','PICKED_UP',2,'Collected at Chiang Mai')
 INTO shipment_tracking VALUES (4,4,DATE '2026-01-05','PICKED_UP',3,'Collected at Khon Kaen')
 INTO shipment_tracking VALUES (5,5,DATE '2026-01-06','PICKED_UP',1,'Collected at Bangkok')
 INTO shipment_tracking VALUES (6,6,DATE '2026-01-07','PICKED_UP',5,'Collected at Rayong')
 INTO shipment_tracking VALUES (7,7,DATE '2026-01-08','PICKED_UP',4,'Collected at Phuket')
 INTO shipment_tracking VALUES (8,8,DATE '2026-01-09','PICKED_UP',1,'Collected at Bangkok')
 INTO shipment_tracking VALUES (9,9,DATE '2026-01-10','PICKED_UP',2,'Collected at Chiang Mai')
 INTO shipment_tracking VALUES (10,10,DATE '2026-01-11','PICKED_UP',3,'Collected at Khon Kaen')
 INTO shipment_tracking VALUES (11,11,DATE '2026-01-12','DEPARTED_DEPOT',1,'Departed Bangkok')
 INTO shipment_tracking VALUES (12,12,DATE '2026-01-13','DEPARTED_DEPOT',4,'Departed Phuket')
SELECT 1 FROM dual;
INSERT ALL
 INTO delivery_receipts VALUES (1,'Ploy N.',DATE '2026-01-04','POD-2026-001','ACCEPTED')
 INTO delivery_receipts VALUES (2,'Krit T.',DATE '2026-01-05','POD-2026-002','ACCEPTED')
 INTO delivery_receipts VALUES (3,'Mina L.',DATE '2026-01-06','POD-2026-003','ACCEPTED')
 INTO delivery_receipts VALUES (4,'Nok P.',DATE '2026-01-07','POD-2026-004','ACCEPTED')
 INTO delivery_receipts VALUES (5,'Aom R.',DATE '2026-01-08','POD-2026-005','ACCEPTED')
 INTO delivery_receipts VALUES (6,'Than P.',DATE '2026-01-09','POD-2026-006','ACCEPTED')
 INTO delivery_receipts VALUES (7,'Lek S.',DATE '2026-01-10','POD-2026-007','ACCEPTED')
 INTO delivery_receipts VALUES (8,'Pim K.',DATE '2026-01-11','POD-2026-008','ACCEPTED')
 INTO delivery_receipts VALUES (9,'Som C.',DATE '2026-01-12','POD-2026-009','ACCEPTED')
 INTO delivery_receipts VALUES (10,'Dao W.',DATE '2026-01-13','POD-2026-010','ACCEPTED')
SELECT 1 FROM dual;
INSERT ALL
 INTO maintenance_records VALUES (1,1,DATE '2025-12-20','SERVICE',25000,1800,'COMPLETED')
 INTO maintenance_records VALUES (2,2,DATE '2025-12-21','INSPECTION',48000,900,'COMPLETED')
 INTO maintenance_records VALUES (3,3,DATE '2025-12-22','TYRES',61000,12000,'COMPLETED')
 INTO maintenance_records VALUES (4,4,DATE '2025-12-23','SERVICE',39000,2500,'COMPLETED')
 INTO maintenance_records VALUES (5,5,DATE '2025-12-24','REPAIR',18000,3200,'COMPLETED')
 INTO maintenance_records VALUES (6,1,DATE '2026-01-15','INSPECTION',26000,900,'COMPLETED')
 INTO maintenance_records VALUES (7,2,DATE '2026-01-16','SERVICE',49000,2100,'COMPLETED')
 INTO maintenance_records VALUES (8,3,DATE '2026-01-17','REPAIR',62000,4500,'COMPLETED')
 INTO maintenance_records VALUES (9,4,DATE '2026-01-18','INSPECTION',40000,900,'COMPLETED')
 INTO maintenance_records VALUES (10,5,DATE '2026-01-19','SERVICE',19000,1600,'COMPLETED')
SELECT 1 FROM dual;
COMMIT;

-- 3. VIEWS ----------------------------------------------------------
CREATE OR REPLACE VIEW v_shipment_operations AS
SELECT s.shipment_id,s.shipment_no,c.customer_name,od.depot_code AS origin_code,
 dd.depot_code AS destination_code,s.booked_on,s.promised_date,s.weight_kg,
 s.freight_charge,s.shipment_status,dr.received_by,dr.received_on,dr.receipt_status
FROM shipments s JOIN customers c ON c.customer_id=s.customer_id
JOIN depots od ON od.depot_id=s.origin_depot_id JOIN depots dd ON dd.depot_id=s.destination_depot_id
LEFT JOIN delivery_receipts dr ON dr.shipment_id=s.shipment_id;
-- Preaggregate legs separately: shipment freight_charge appears once, regardless of leg count.
CREATE OR REPLACE VIEW v_trip_load_summary AS
SELECT t.trip_id,t.trip_no,t.planned_departure,t.trip_status,v.registration_no,
 d.full_name AS driver_name,sd.depot_code AS start_code,ed.depot_code AS end_code,
 v.capacity_kg,NVL(x.loaded_kg,0) AS loaded_kg,NVL(x.shipment_count,0) AS shipment_count,
 ROUND(NVL(x.loaded_kg,0)/v.capacity_kg*100,2) AS capacity_percent
FROM trips t JOIN vehicles v ON v.vehicle_id=t.vehicle_id LEFT JOIN drivers d ON d.driver_id=t.driver_id
JOIN depots sd ON sd.depot_id=t.start_depot_id JOIN depots ed ON ed.depot_id=t.end_depot_id
LEFT JOIN (SELECT trip_id,SUM(loaded_kg) loaded_kg,COUNT(*) shipment_count FROM trip_shipments GROUP BY trip_id) x ON x.trip_id=t.trip_id;
CREATE OR REPLACE VIEW v_top5_customers AS
SELECT customer_id,customer_name,total_freight FROM (
 SELECT c.customer_id,c.customer_name,SUM(s.freight_charge) total_freight
 FROM customers c JOIN shipments s ON s.customer_id=c.customer_id
 WHERE s.shipment_status <> 'CANCELLED' GROUP BY c.customer_id,c.customer_name
 ORDER BY total_freight DESC,c.customer_id
) WHERE ROWNUM <= 5;

-- 4. REQUIRED QUERIES ----------------------------------------------
SELECT * FROM v_shipment_operations ORDER BY shipment_id;
SELECT c.customer_id,c.customer_name,COUNT(s.shipment_id) shipment_count
FROM customers c JOIN shipments s ON s.customer_id=c.customer_id
GROUP BY c.customer_id,c.customer_name HAVING COUNT(s.shipment_id)>=2 ORDER BY shipment_count DESC,c.customer_id;
SELECT shipment_no,customer_name,freight_charge FROM v_shipment_operations
WHERE freight_charge > (SELECT AVG(freight_charge) FROM shipments) ORDER BY freight_charge DESC,shipment_no;
SELECT c.customer_name,x.total_freight FROM customers c JOIN
 (SELECT customer_id,SUM(freight_charge) total_freight FROM shipments GROUP BY customer_id) x
 ON x.customer_id=c.customer_id WHERE x.total_freight>4000 ORDER BY x.total_freight DESC,c.customer_id;
SELECT * FROM (SELECT shipment_no,customer_name,freight_charge FROM v_shipment_operations
 ORDER BY freight_charge DESC,shipment_no) WHERE ROWNUM<=5;
SELECT CASE WHEN GROUPING(d.province)=1 THEN 'ALL PROVINCES' ELSE d.province END AS origin_province,
 CASE WHEN GROUPING(s.shipment_status)=1 THEN 'ALL STATUSES' ELSE s.shipment_status END AS shipment_status,
 SUM(s.freight_charge) freight_total,GROUPING(d.province) province_grouped,GROUPING(s.shipment_status) status_grouped
FROM shipments s JOIN depots d ON d.depot_id=s.origin_depot_id
GROUP BY ROLLUP(d.province,s.shipment_status) ORDER BY GROUPING(d.province),d.province,GROUPING(s.shipment_status),s.shipment_status;
SELECT * FROM v_trip_load_summary ORDER BY trip_id;
SELECT * FROM v_top5_customers ORDER BY total_freight DESC,customer_id;

-- 5. DML / TRANSACTIONS --------------------------------------------
INSERT INTO customers (customer_id,customer_name,contact_email) VALUES (900001,'Transaction Demo','transaction@fleet.example');
COMMIT;
UPDATE customers SET customer_name='Uncommitted Name' WHERE customer_id=900001;
ROLLBACK;
SELECT customer_name,customer_status FROM customers WHERE customer_id=900001;
DELETE FROM customers c WHERE c.customer_id=900001
 AND NOT EXISTS (SELECT 1 FROM shipments s WHERE s.customer_id=c.customer_id);
COMMIT;
SAVEPOINT before_vehicle_demo;
UPDATE vehicles SET vehicle_status='MAINTENANCE' WHERE vehicle_id IN
 (SELECT vehicle_id FROM maintenance_records WHERE maintenance_type='REPAIR');
SELECT vehicle_id,vehicle_status FROM vehicles ORDER BY vehicle_id;
ROLLBACK TO before_vehicle_demo;
COMMIT;

-- 6. ROLLBACK-SAFE CONSTRAINT AND REFERENTIAL-ACTION TESTS ----------
DECLARE
 PROCEDURE expect_error(p_label VARCHAR2,p_sql VARCHAR2,p_expected NUMBER) IS v_code NUMBER;
 BEGIN SAVEPOINT test_case; BEGIN EXECUTE IMMEDIATE p_sql; EXCEPTION WHEN OTHERS THEN
  v_code:=SQLCODE; ROLLBACK TO test_case; IF v_code=p_expected THEN DBMS_OUTPUT.PUT_LINE('PASS: '||p_label||' ('||v_code||')'); RETURN; END IF; RAISE; END;
  ROLLBACK TO test_case; RAISE_APPLICATION_ERROR(-20001,'FAIL: '||p_label||' unexpectedly succeeded); END;
BEGIN
 expect_error('Duplicate shipment PK',q'[INSERT INTO shipments VALUES (1,'X',1,1,2,DATE '2026-01-01',DATE '2026-01-02',1,1,'BOOKED')]',-1);
 expect_error('Unique shipment number',q'[INSERT INTO shipments VALUES (900002,'SHP-2026-001',1,1,2,DATE '2026-01-01',DATE '2026-01-02',1,1,'BOOKED')]',-1);
 expect_error('NOT NULL customer',q'[INSERT INTO customers VALUES (900002,NULL,'null@fleet.example',NULL,'ACTIVE')]',-1400);
 expect_error('Missing origin depot FK',q'[INSERT INTO shipments VALUES (900002,'NEW',1,999,2,DATE '2026-01-01',DATE '2026-01-02',1,1,'BOOKED')]',-2291);
 expect_error('Different shipment depots',q'[UPDATE shipments SET destination_depot_id=origin_depot_id WHERE shipment_id=1]',-2290);
 expect_error('Positive vehicle capacity',q'[UPDATE vehicles SET capacity_kg=0 WHERE vehicle_id=1]',-2290);
 expect_error('One receipt per shipment',q'[INSERT INTO delivery_receipts VALUES (1,'Test',DATE '2026-01-01','POD-X','ACCEPTED')]',-1);
 expect_error('Trip allocation protects shipment parent',q'[DELETE FROM shipments WHERE shipment_id=1]',-2292);
END;
/
DECLARE v_count NUMBER; BEGIN SAVEPOINT actions_test;
 INSERT INTO depots VALUES (900003,'TMP','Temporary Depot','Bangkok',13.70,100.50,'ACTIVE');
 INSERT INTO vehicles VALUES (900003,'TMP-1','VAN',500,'AVAILABLE',900003);
 DELETE FROM depots WHERE depot_id=900003;
 SELECT COUNT(*) INTO v_count FROM vehicles WHERE vehicle_id=900003 AND current_depot_id IS NULL;
 IF v_count<>1 THEN RAISE_APPLICATION_ERROR(-20002,'SET NULL failed'); END IF; DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE SET NULL');
 INSERT INTO shipments VALUES (900003,'TMP-SHP',1,1,2,DATE '2026-02-01',DATE '2026-02-02',10,100,'BOOKED');
 INSERT INTO shipment_tracking VALUES (900003,900003,DATE '2026-02-01','BOOKED',1,'test');
 INSERT INTO delivery_receipts VALUES (900003,'Test',DATE '2026-02-02','POD-TMP','ACCEPTED');
 DELETE FROM shipments WHERE shipment_id=900003;
 SELECT (SELECT COUNT(*) FROM shipment_tracking WHERE shipment_id=900003)+(SELECT COUNT(*) FROM delivery_receipts WHERE shipment_id=900003) INTO v_count FROM dual;
 IF v_count<>0 THEN RAISE_APPLICATION_ERROR(-20003,'CASCADE failed'); END IF; DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE CASCADE'); ROLLBACK TO actions_test;
EXCEPTION WHEN OTHERS THEN ROLLBACK TO actions_test; RAISE; END;
/
COMMIT;

-- 7. AUDIT AND STATIC-OPERATIONAL DIAGNOSTICS -----------------------
SELECT 'CUSTOMERS' table_name,COUNT(*) row_count FROM customers UNION ALL SELECT 'DEPOTS',COUNT(*) FROM depots UNION ALL SELECT 'DRIVERS',COUNT(*) FROM drivers UNION ALL SELECT 'VEHICLES',COUNT(*) FROM vehicles UNION ALL SELECT 'SHIPMENTS',COUNT(*) FROM shipments UNION ALL SELECT 'SHIPMENT_TRACKING',COUNT(*) FROM shipment_tracking UNION ALL SELECT 'DELIVERY_RECEIPTS',COUNT(*) FROM delivery_receipts UNION ALL SELECT 'TRIPS',COUNT(*) FROM trips UNION ALL SELECT 'TRIP_SHIPMENTS',COUNT(*) FROM trip_shipments UNION ALL SELECT 'MAINTENANCE_RECORDS',COUNT(*) FROM maintenance_records;
-- Expected: 5,5,5,5,12,12,10,10,14,10. Diagnostics should return zero rows.
SELECT ts.trip_id,SUM(ts.loaded_kg) loaded_kg,v.capacity_kg FROM trip_shipments ts JOIN trips t ON t.trip_id=ts.trip_id JOIN vehicles v ON v.vehicle_id=t.vehicle_id GROUP BY ts.trip_id,v.capacity_kg HAVING SUM(ts.loaded_kg)>v.capacity_kg;
SELECT a.vehicle_id,a.trip_id trip_a,b.trip_id trip_b FROM trips a JOIN trips b ON b.vehicle_id=a.vehicle_id AND b.trip_id>a.trip_id WHERE a.trip_status<>'CANCELLED' AND b.trip_status<>'CANCELLED' AND a.planned_departure<b.planned_arrival AND b.planned_departure<a.planned_arrival;
SELECT ts.trip_id,ts.shipment_id FROM trip_shipments ts JOIN trips t ON t.trip_id=ts.trip_id JOIN shipments s ON s.shipment_id=ts.shipment_id WHERE t.start_depot_id<>s.origin_depot_id AND t.end_depot_id<>s.destination_depot_id;

-- 8. OPTIONAL DBA-ENABLED ROLES; hosted APEX normally leaves FALSE --
DECLARE c_enable_security CONSTANT BOOLEAN := FALSE; BEGIN IF c_enable_security THEN
 EXECUTE IMMEDIATE 'CREATE ROLE lf_dispatcher'; EXECUTE IMMEDIATE 'CREATE ROLE lf_manager';
 EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON customers TO lf_dispatcher'; EXECUTE IMMEDIATE 'GRANT SELECT ON depots TO lf_dispatcher'; EXECUTE IMMEDIATE 'GRANT SELECT ON vehicles TO lf_dispatcher'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON shipments TO lf_dispatcher'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON shipment_tracking TO lf_dispatcher'; EXECUTE IMMEDIATE 'GRANT SELECT ON v_shipment_operations TO lf_dispatcher'; EXECUTE IMMEDIATE 'GRANT lf_dispatcher TO lf_manager'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON trips TO lf_manager'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON trip_shipments TO lf_manager'; EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON maintenance_records TO lf_manager'; EXECUTE IMMEDIATE 'GRANT SELECT ON v_trip_load_summary TO lf_manager';
 ELSE DBMS_OUTPUT.PUT_LINE('NOT RUN: optional CREATE ROLE / GRANT section.'); END IF; END;
/
SELECT table_name,constraint_name,constraint_type,status FROM user_constraints WHERE table_name IN ('CUSTOMERS','DEPOTS','DRIVERS','VEHICLES','SHIPMENTS','SHIPMENT_TRACKING','DELIVERY_RECEIPTS','TRIPS','TRIP_SHIPMENTS','MAINTENANCE_RECORDS') ORDER BY table_name,constraint_type,constraint_name;
SELECT object_name,status FROM user_objects WHERE object_name IN ('V_SHIPMENT_OPERATIONS','V_TRIP_LOAD_SUMMARY','V_TOP5_CUSTOMERS');
