/* HEALTHCARE CLINIC DATABASE -- Oracle 19c+ / Oracle APEX SQL Workshop
   Run once in a FRESH schema. No application code and no destructive reset.
   All names, contacts, dates and clinical records below are fictional teaching data,
   not actual patient health information. Currency: THB. Authored statically only;
   NOT executed against an Oracle database by the authoring assistant.
   Exactly 10 tables. Oracle DDL commits implicitly; do not rerun over existing objects.
   Historical billable facts are unit rates; invoice/payment totals are calculated in views.
   A prescription records a clinician's order, not a dispensation or dosing advice.
*/

-- 1. TABLES AND CONSTRAINTS -----------------------------------------
CREATE TABLE patients (
 patient_id NUMBER(6) CONSTRAINT pk_patients PRIMARY KEY,
 full_name VARCHAR2(100) NOT NULL,
 email VARCHAR2(120) NOT NULL CONSTRAINT uq_patient_email UNIQUE,
 phone VARCHAR2(25),
 registration_date DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
 patient_status VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_patient_status CHECK (patient_status IN ('ACTIVE','INACTIVE'))
);

-- Optional shared-PK 1:1 extension: a patient can be registered before a profile is completed.
CREATE TABLE patient_profiles (
 patient_id NUMBER(6) CONSTRAINT pk_patient_profiles PRIMARY KEY,
 preferred_name VARCHAR2(60),
 contact_preference VARCHAR2(10) DEFAULT 'EMAIL' NOT NULL,
 locality VARCHAR2(60) NOT NULL,
 emergency_contact_type VARCHAR2(60),
 CONSTRAINT fk_profile_patient FOREIGN KEY (patient_id)
  REFERENCES patients(patient_id) ON DELETE CASCADE,
 CONSTRAINT ck_contact_preference CHECK (contact_preference IN ('EMAIL','PHONE'))
);

CREATE TABLE departments (
 department_id NUMBER(6) CONSTRAINT pk_departments PRIMARY KEY,
 department_name VARCHAR2(80) NOT NULL CONSTRAINT uq_department_name UNIQUE,
 consultation_rate NUMBER(10,2) NOT NULL CONSTRAINT ck_department_rate CHECK (consultation_rate > 0),
 department_status VARCHAR2(15) DEFAULT 'OPEN' NOT NULL,
 CONSTRAINT ck_department_status CHECK (department_status IN ('OPEN','CLOSED'))
);

CREATE TABLE doctors (
 doctor_id NUMBER(6) CONSTRAINT pk_doctors PRIMARY KEY,
 department_id NUMBER(6) NOT NULL CONSTRAINT fk_doctor_department
  REFERENCES departments(department_id),
 full_name VARCHAR2(100) NOT NULL,
 professional_code VARCHAR2(30) NOT NULL CONSTRAINT uq_doctor_code UNIQUE,
 doctor_status VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_doctor_status CHECK (doctor_status IN ('ACTIVE','INACTIVE'))
);

CREATE TABLE appointments (
 appointment_id NUMBER(6) CONSTRAINT pk_appointments PRIMARY KEY,
 patient_id NUMBER(6) NOT NULL CONSTRAINT fk_appointment_patient REFERENCES patients(patient_id),
 doctor_id NUMBER(6) CONSTRAINT fk_appointment_doctor REFERENCES doctors(doctor_id) ON DELETE SET NULL,
 appointment_at DATE NOT NULL,
 appointment_status VARCHAR2(15) DEFAULT 'SCHEDULED' NOT NULL,
 visit_note VARCHAR2(250),
 CONSTRAINT ck_appointment_status CHECK (appointment_status IN ('SCHEDULED','COMPLETED','CANCELLED'))
);

CREATE TABLE medications (
 medication_id NUMBER(6) CONSTRAINT pk_medications PRIMARY KEY,
 medication_name VARCHAR2(100) NOT NULL CONSTRAINT uq_medication_name UNIQUE,
 form_name VARCHAR2(40) NOT NULL,
 list_unit_rate NUMBER(10,2) NOT NULL CONSTRAINT ck_medication_rate CHECK (list_unit_rate > 0),
 catalog_status VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_medication_status CHECK (catalog_status IN ('ACTIVE','INACTIVE'))
);

-- Header is tied to one appointment. Its clinical content is intentionally limited.
CREATE TABLE prescriptions (
 prescription_id NUMBER(6) CONSTRAINT pk_prescriptions PRIMARY KEY,
 appointment_id NUMBER(6) NOT NULL CONSTRAINT fk_prescription_appointment REFERENCES appointments(appointment_id),
 prescribed_on DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
 prescription_status VARCHAR2(15) DEFAULT 'ISSUED' NOT NULL,
 clinician_note VARCHAR2(250),
 CONSTRAINT ck_prescription_status CHECK (prescription_status IN ('DRAFT','ISSUED','CANCELLED'))
);

-- Resolves prescription <-> medication M:N; quantity and historical unit rate are order facts.
CREATE TABLE prescription_items (
 prescription_id NUMBER(6) CONSTRAINT fk_item_prescription
  REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
 medication_id NUMBER(6) CONSTRAINT fk_item_medication REFERENCES medications(medication_id),
 quantity NUMBER(5) DEFAULT 1 NOT NULL CONSTRAINT ck_item_quantity CHECK (quantity > 0),
 unit_rate NUMBER(10,2) NOT NULL CONSTRAINT ck_item_rate CHECK (unit_rate > 0),
 CONSTRAINT pk_prescription_items PRIMARY KEY (prescription_id, medication_id)
);

-- Optional 1:1: a completed appointment may have zero or one invoice.
CREATE TABLE invoices (
 invoice_id NUMBER(6) CONSTRAINT pk_invoices PRIMARY KEY,
 appointment_id NUMBER(6) NOT NULL CONSTRAINT uq_invoice_appointment UNIQUE,
 issued_on DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
 due_on DATE NOT NULL,
 invoice_status VARCHAR2(15) DEFAULT 'OPEN' NOT NULL,
 CONSTRAINT fk_invoice_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
 CONSTRAINT ck_invoice_dates CHECK (due_on >= issued_on),
 CONSTRAINT ck_invoice_status CHECK (invoice_status IN ('OPEN','PAID','VOID'))
);

CREATE TABLE payments (
 payment_id NUMBER(6) CONSTRAINT pk_payments PRIMARY KEY,
 invoice_id NUMBER(6) NOT NULL CONSTRAINT fk_payment_invoice REFERENCES invoices(invoice_id),
 paid_on DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
 amount NUMBER(10,2) NOT NULL CONSTRAINT ck_payment_amount CHECK (amount > 0),
 payment_method VARCHAR2(15) NOT NULL,
 payment_reference VARCHAR2(60) NOT NULL CONSTRAINT uq_payment_reference UNIQUE,
 CONSTRAINT ck_payment_method CHECK (payment_method IN ('CASH','CARD','TRANSFER'))
);

-- CASCADE is limited to a private profile extension and prescription lines; neither can survive its owner.
-- Patient, appointment, invoice and payment FKs remain restrictive to preserve care and financial history.
-- SET NULL preserves an appointment if a doctor account is removed/deactivated from the roster.
CREATE INDEX ix_doctor_department ON doctors(department_id);
CREATE INDEX ix_appointment_patient ON appointments(patient_id);
CREATE INDEX ix_appointment_doctor ON appointments(doctor_id);
CREATE INDEX ix_prescription_appointment ON prescriptions(appointment_id);
CREATE INDEX ix_item_medication ON prescription_items(medication_id);
CREATE INDEX ix_payment_invoice ON payments(invoice_id);

-- 2. FICTIONAL SEED DATA --------------------------------------------
INSERT ALL
 INTO patients VALUES (1,'Ari Niran','ari.niran@example.test',NULL,DATE '2026-01-02','ACTIVE')
 INTO patients VALUES (2,'Mila Kwan','mila.kwan@example.test',NULL,DATE '2026-01-03','ACTIVE')
 INTO patients VALUES (3,'Theo Ban','theo.ban@example.test',NULL,DATE '2026-01-04','ACTIVE')
 INTO patients VALUES (4,'Nora Vale','nora.vale@example.test',NULL,DATE '2026-01-05','ACTIVE')
 INTO patients VALUES (5,'Ivo Rune','ivo.rune@example.test',NULL,DATE '2026-01-06','ACTIVE')
 INTO patients VALUES (6,'Sana Wren','sana.wren@example.test',NULL,DATE '2026-01-07','ACTIVE')
 INTO patients VALUES (7,'Oren Pike','oren.pike@example.test',NULL,DATE '2026-01-08','ACTIVE')
 INTO patients VALUES (8,'Lia Moss','lia.moss@example.test',NULL,DATE '2026-01-09','ACTIVE')
 INTO patients VALUES (9,'Kian Sol','kian.sol@example.test',NULL,DATE '2026-01-10','ACTIVE')
 INTO patients VALUES (10,'Eva Dune','eva.dune@example.test',NULL,DATE '2026-01-11','ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO patient_profiles VALUES (1,'Ari','EMAIL','North District','Household contact')
 INTO patient_profiles VALUES (2,'Mila','PHONE','River District','Household contact')
 INTO patient_profiles VALUES (3,'Theo','EMAIL','Garden District','Household contact')
 INTO patient_profiles VALUES (4,'Nora','EMAIL','Market District','Household contact')
 INTO patient_profiles VALUES (5,'Ivo','PHONE','Lake District','Household contact')
 INTO patient_profiles VALUES (6,'Sana','EMAIL','Hill District','Household contact')
 INTO patient_profiles VALUES (7,'Oren','PHONE','East District','Household contact')
 INTO patient_profiles VALUES (8,'Lia','EMAIL','West District','Household contact')
 INTO patient_profiles VALUES (9,'Kian','PHONE','Central District','Household contact')
 INTO patient_profiles VALUES (10,'Eva','EMAIL','South District','Household contact')
SELECT 1 FROM dual;
INSERT ALL
 INTO departments VALUES (1,'General Practice',650,'OPEN')
 INTO departments VALUES (2,'Dermatology',800,'OPEN')
 INTO departments VALUES (3,'Cardiology',1100,'OPEN')
 INTO departments VALUES (4,'Pediatrics',700,'OPEN')
 INTO departments VALUES (5,'Rehabilitation',750,'OPEN')
SELECT 1 FROM dual;
INSERT ALL
 INTO doctors VALUES (1,1,'Dr. Rowan Hale','DOC-GP-01','ACTIVE')
 INTO doctors VALUES (2,2,'Dr. Mira Chen','DOC-DE-02','ACTIVE')
 INTO doctors VALUES (3,3,'Dr. Leon Park','DOC-CA-03','ACTIVE')
 INTO doctors VALUES (4,4,'Dr. Eva Noor','DOC-PE-04','ACTIVE')
 INTO doctors VALUES (5,5,'Dr. Tomas Reed','DOC-RH-05','ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO medications VALUES (1,'Fictional Med A','Tablet',25,'ACTIVE')
 INTO medications VALUES (2,'Fictional Med B','Capsule',30,'ACTIVE')
 INTO medications VALUES (3,'Fictional Med C','Topical',45,'ACTIVE')
 INTO medications VALUES (4,'Fictional Med D','Liquid',20,'ACTIVE')
 INTO medications VALUES (5,'Fictional Med E','Patch',55,'ACTIVE')
SELECT 1 FROM dual;

-- 12 appointments, prescriptions, invoices and payments; no clinical diagnosis or dosing advice is seeded.
DECLARE
 v_visit DATE;
 v_rate NUMBER;
BEGIN
 FOR i IN 1..12 LOOP
  v_visit := DATE '2026-02-01' + (i-1)*2;
  SELECT consultation_rate INTO v_rate FROM departments WHERE department_id=MOD(i-1,5)+1;
  INSERT INTO appointments VALUES
   (i,MOD(i-1,10)+1,MOD(i-1,5)+1,v_visit+9/24,'COMPLETED','Fictional teaching visit record');
  INSERT INTO prescriptions VALUES
   (i,i,v_visit,'ISSUED','Fictional order record; not a dispensing event');
  INSERT INTO prescription_items VALUES (i,MOD(i-1,5)+1,1,v_rate/100);
  INSERT INTO invoices VALUES (i,i,v_visit,v_visit+14,'OPEN');
  INSERT INTO payments VALUES (i,i,v_visit,200,'CARD','HC-PAY-'||TO_CHAR(i,'FM000'));
 END LOOP;
 -- Additional lines demonstrate multi-medication orders, producing 14 detail rows.
 INSERT INTO prescription_items VALUES (1,2,1,30);
 INSERT INTO prescription_items VALUES (3,4,1,20);
END;
/
COMMIT;

-- 3. VIEWS ----------------------------------------------------------
-- V1: operational multi-table appointment summary; no contact or sensitive profile fields.
CREATE OR REPLACE VIEW v_appointment_summary AS
SELECT a.appointment_id,a.appointment_at,a.appointment_status,
       p.patient_id,p.full_name AS patient_name,
       d.full_name AS doctor_name,dp.department_name,dp.consultation_rate,
       pr.prescription_id,pr.prescription_status
FROM appointments a
JOIN patients p ON p.patient_id=a.patient_id
LEFT JOIN doctors d ON d.doctor_id=a.doctor_id
LEFT JOIN departments dp ON dp.department_id=d.department_id
LEFT JOIN prescriptions pr ON pr.appointment_id=a.appointment_id;

-- V2: monetary summary. Prescription lines and payments are preaggregated separately,
-- preventing child-row fanout. It reports order-line rates, not a dispensation amount.
CREATE OR REPLACE VIEW v_invoice_summary AS
SELECT i.invoice_id,i.appointment_id,p.full_name AS patient_name,
       dp.department_name,i.issued_on,i.due_on,i.invoice_status,
       NVL(dp.consultation_rate,0) AS consultation_charge,
       NVL(rx.medication_charge,0) AS medication_order_charge,
       NVL(dp.consultation_rate,0)+NVL(rx.medication_charge,0) AS invoice_charge,
       NVL(pay.paid_total,0) AS paid_total,
       NVL(dp.consultation_rate,0)+NVL(rx.medication_charge,0)-NVL(pay.paid_total,0) AS balance_due
FROM invoices i
JOIN appointments a ON a.appointment_id=i.appointment_id
JOIN patients p ON p.patient_id=a.patient_id
LEFT JOIN doctors d ON d.doctor_id=a.doctor_id
LEFT JOIN departments dp ON dp.department_id=d.department_id
LEFT JOIN (
 SELECT pr.appointment_id,SUM(pi.quantity*pi.unit_rate) AS medication_charge
 FROM prescriptions pr JOIN prescription_items pi ON pi.prescription_id=pr.prescription_id
 GROUP BY pr.appointment_id
) rx ON rx.appointment_id=i.appointment_id
LEFT JOIN (
 SELECT invoice_id,SUM(amount) AS paid_total FROM payments GROUP BY invoice_id
) pay ON pay.invoice_id=i.invoice_id;

-- V3: restricted Top-N billing summary, sorted inside then filtered by ROWNUM outside.
CREATE OR REPLACE VIEW v_top5_patient_charges AS
SELECT patient_id,patient_name,total_charged
FROM (
 SELECT p.patient_id,p.full_name AS patient_name,SUM(s.invoice_charge) AS total_charged
 FROM patients p JOIN appointments a ON a.patient_id=p.patient_id
 JOIN v_invoice_summary s ON s.appointment_id=a.appointment_id
 GROUP BY p.patient_id,p.full_name
 ORDER BY total_charged DESC,p.patient_id
)
WHERE ROWNUM<=5;

-- 4. REQUIRED QUERIES ----------------------------------------------
-- Q1 JOIN: appointment, patient, doctor, department and prescription summary.
SELECT * FROM v_appointment_summary ORDER BY appointment_id;

-- Q2 GROUP BY/HAVING: patients with more than one completed appointment.
SELECT p.patient_id,p.full_name,COUNT(a.appointment_id) AS completed_visit_count
FROM patients p JOIN appointments a ON a.patient_id=p.patient_id
WHERE a.appointment_status='COMPLETED'
GROUP BY p.patient_id,p.full_name
HAVING COUNT(a.appointment_id)>=2
ORDER BY completed_visit_count DESC,p.patient_id;

-- Q3 scalar subquery: invoices above the average computed charge.
SELECT invoice_id,patient_name,invoice_charge
FROM v_invoice_summary
WHERE invoice_charge>(SELECT AVG(invoice_charge) FROM v_invoice_summary)
ORDER BY invoice_charge DESC,invoice_id;

-- Q4 FROM-clause subquery: patients whose cumulative computed charge exceeds THB 1,500.
SELECT p.full_name,x.total_charged
FROM patients p JOIN (
 SELECT a.patient_id,SUM(s.invoice_charge) AS total_charged
 FROM appointments a JOIN v_invoice_summary s ON s.appointment_id=a.appointment_id
 GROUP BY a.patient_id
) x ON x.patient_id=p.patient_id
WHERE x.total_charged>1500
ORDER BY x.total_charged DESC,p.patient_id;

-- Q5 ordered inline Top-N: sorting precedes ROWNUM.
SELECT * FROM (
 SELECT invoice_id,patient_name,balance_due FROM v_invoice_summary
 ORDER BY balance_due DESC,invoice_id
) WHERE ROWNUM<=5;

-- Q6 ROLLUP + GROUPING: consultation charges by department/status and totals.
SELECT CASE WHEN GROUPING(dp.department_name)=1 THEN 'ALL DEPARTMENTS' ELSE dp.department_name END AS department_name,
       CASE WHEN GROUPING(a.appointment_status)=1 THEN 'ALL STATUSES' ELSE a.appointment_status END AS appointment_status,
       SUM(dp.consultation_rate) AS consultation_charge,
       GROUPING(dp.department_name) AS department_grouped,
       GROUPING(a.appointment_status) AS status_grouped
FROM appointments a JOIN doctors d ON d.doctor_id=a.doctor_id
JOIN departments dp ON dp.department_id=d.department_id
GROUP BY ROLLUP(dp.department_name,a.appointment_status)
ORDER BY GROUPING(dp.department_name),dp.department_name,GROUPING(a.appointment_status),a.appointment_status;

SELECT * FROM v_invoice_summary ORDER BY invoice_id;
SELECT * FROM v_top5_patient_charges ORDER BY total_charged DESC,patient_id;

-- 5. DML, CONDITIONAL SUBQUERY, COMMIT AND ROLLBACK -----------------
INSERT INTO patients (patient_id,full_name,email,registration_date)
VALUES (900001,'Transaction Demo','transaction.demo@example.test',DATE '2026-03-01');
COMMIT;
UPDATE patients SET full_name='Uncommitted Name' WHERE patient_id=900001;
ROLLBACK;
-- Expected after rollback: Transaction Demo and patient_status ACTIVE.
SELECT full_name,patient_status FROM patients WHERE patient_id=900001;

-- Conditional DELETE only deletes the temporary patient if no clinical appointment exists.
DELETE FROM patients p WHERE p.patient_id=900001
AND NOT EXISTS (SELECT 1 FROM appointments a WHERE a.patient_id=p.patient_id);
COMMIT;

-- Conditional UPDATE via subquery, then rollback leaves catalog facts unchanged.
SAVEPOINT before_rate_demo;
UPDATE medications SET list_unit_rate=list_unit_rate*1.05
WHERE medication_id IN (SELECT medication_id FROM prescription_items WHERE quantity>=1);
SELECT medication_name,list_unit_rate FROM medications ORDER BY medication_id;
ROLLBACK TO before_rate_demo;
COMMIT;

-- 6. ROLLBACK-SAFE NEGATIVE CONSTRAINT TESTS ------------------------
-- Expected errors are accepted only when SQLCODE matches; unexpected errors are re-raised.
DECLARE
 PROCEDURE expect_error(p_label VARCHAR2,p_sql VARCHAR2,p_expected NUMBER) IS v_code NUMBER;
 BEGIN
  SAVEPOINT test_case;
  BEGIN
   EXECUTE IMMEDIATE p_sql;
  EXCEPTION WHEN OTHERS THEN
   v_code:=SQLCODE;
   ROLLBACK TO test_case;
   IF v_code=p_expected THEN
    DBMS_OUTPUT.PUT_LINE('PASS: '||p_label||' (SQLCODE '||v_code||')'); RETURN;
   END IF;
   RAISE;
  END;
  ROLLBACK TO test_case;
  RAISE_APPLICATION_ERROR(-20001,'FAIL: '||p_label||' unexpectedly succeeded');
 END;
BEGIN
 expect_error('Duplicate patient primary key',q'[INSERT INTO patients VALUES (1,'Test','unique@example.test',NULL,DATE '2026-01-01','ACTIVE')]',-1);
 expect_error('Unique patient email',q'[INSERT INTO patients VALUES (900002,'Test','ari.niran@example.test',NULL,DATE '2026-01-01','ACTIVE')]',-1);
 expect_error('NOT NULL patient name',q'[INSERT INTO patients VALUES (900002,NULL,'null@example.test',NULL,DATE '2026-01-01','ACTIVE')]',-1400);
 expect_error('Doctor department foreign key',q'[INSERT INTO doctors VALUES (900002,999999,'Test Doctor','DOC-TEST','ACTIVE')]',-2291);
 expect_error('Positive department rate',q'[UPDATE departments SET consultation_rate=0 WHERE department_id=1]',-2290);
 expect_error('Positive prescription quantity',q'[UPDATE prescription_items SET quantity=0 WHERE prescription_id=1 AND medication_id=1]',-2290);
 expect_error('Positive payment amount',q'[UPDATE payments SET amount=0 WHERE payment_id=1]',-2290);
 expect_error('One invoice per appointment',q'[INSERT INTO invoices VALUES (900002,1,DATE '2026-02-01',DATE '2026-02-15','OPEN')]',-1);
 expect_error('Invoice protects appointment history',q'[DELETE FROM appointments WHERE appointment_id=1]',-2292);
END;
/

-- Referential actions are tested with temporary rows and rolled back.
DECLARE v_count NUMBER;
BEGIN
 SAVEPOINT actions_test;
 INSERT INTO doctors VALUES (900003,1,'Temporary Doctor','DOC-TEMP','ACTIVE');
 INSERT INTO appointments VALUES (900003,1,900003,DATE '2026-03-10','SCHEDULED','Temporary test visit');
 DELETE FROM doctors WHERE doctor_id=900003;
 SELECT COUNT(*) INTO v_count FROM appointments WHERE appointment_id=900003 AND doctor_id IS NULL;
 IF v_count<>1 THEN RAISE_APPLICATION_ERROR(-20002,'SET NULL failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE SET NULL');
 INSERT INTO prescriptions VALUES (900003,900003,DATE '2026-03-10','DRAFT','Temporary draft');
 INSERT INTO prescription_items VALUES (900003,1,1,25);
 DELETE FROM prescriptions WHERE prescription_id=900003;
 SELECT COUNT(*) INTO v_count FROM prescription_items WHERE prescription_id=900003;
 IF v_count<>0 THEN RAISE_APPLICATION_ERROR(-20003,'CASCADE failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE CASCADE for prescription items');
 ROLLBACK TO actions_test;
EXCEPTION WHEN OTHERS THEN ROLLBACK TO actions_test; RAISE;
END;
/
COMMIT;

-- 7. DATA AUDIT -----------------------------------------------------
-- Expected rows: 10,10,5,5,12,5,12,14,12,12 respectively.
SELECT 'PATIENTS' table_name,COUNT(*) row_count FROM patients
UNION ALL SELECT 'PATIENT_PROFILES',COUNT(*) FROM patient_profiles
UNION ALL SELECT 'DEPARTMENTS',COUNT(*) FROM departments
UNION ALL SELECT 'DOCTORS',COUNT(*) FROM doctors
UNION ALL SELECT 'APPOINTMENTS',COUNT(*) FROM appointments
UNION ALL SELECT 'MEDICATIONS',COUNT(*) FROM medications
UNION ALL SELECT 'PRESCRIPTIONS',COUNT(*) FROM prescriptions
UNION ALL SELECT 'PRESCRIPTION_ITEMS',COUNT(*) FROM prescription_items
UNION ALL SELECT 'INVOICES',COUNT(*) FROM invoices
UNION ALL SELECT 'PAYMENTS',COUNT(*) FROM payments;

-- Cross-row diagnostics; expected zero rows for the seed but not enforced by CHECK constraints.
-- A: completed appointments lacking an issued prescription.
SELECT a.appointment_id FROM appointments a WHERE a.appointment_status='COMPLETED'
AND NOT EXISTS (SELECT 1 FROM prescriptions pr WHERE pr.appointment_id=a.appointment_id AND pr.prescription_status='ISSUED');
-- B: payment amounts exceeding computed invoice charge.
SELECT invoice_id,balance_due FROM v_invoice_summary WHERE balance_due<0;
-- C: prescriptions without a line item.
SELECT pr.prescription_id FROM prescriptions pr
WHERE NOT EXISTS (SELECT 1 FROM prescription_items pi WHERE pi.prescription_id=pr.prescription_id);

-- 8. SECURITY: OPTIONAL DBA-ENABLED SECTION -------------------------
-- Hosted APEX schemas commonly lack CREATE ROLE. Leave FALSE by default.
DECLARE c_enable_security CONSTANT BOOLEAN := FALSE;
BEGIN
 IF c_enable_security THEN
  EXECUTE IMMEDIATE 'CREATE ROLE hc_reception';
  EXECUTE IMMEDIATE 'CREATE ROLE hc_finance';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON patients TO hc_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON patient_profiles TO hc_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON doctors TO hc_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON departments TO hc_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON appointments TO hc_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_appointment_summary TO hc_reception';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_invoice_summary TO hc_finance';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON invoices TO hc_finance';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON payments TO hc_finance';
  DBMS_OUTPUT.PUT_LINE('Roles created; DBA must assign them to database users.');
 ELSE
  DBMS_OUTPUT.PUT_LINE('NOT RUN: optional CREATE ROLE / GRANT section requires DBA approval.');
 END IF;
END;
/
-- These broad database roles are illustrative only: they are not row-level privacy, consent,
-- break-glass, audit logging, encryption, or APEX application authorization.

SELECT table_name,constraint_name,constraint_type,status FROM user_constraints
WHERE table_name IN ('PATIENTS','PATIENT_PROFILES','DEPARTMENTS','DOCTORS','APPOINTMENTS','MEDICATIONS','PRESCRIPTIONS','PRESCRIPTION_ITEMS','INVOICES','PAYMENTS')
ORDER BY table_name,constraint_type,constraint_name;
SELECT object_name,status FROM user_objects
WHERE object_name IN ('V_APPOINTMENT_SUMMARY','V_INVOICE_SUMMARY','V_TOP5_PATIENT_CHARGES');
-- END OF SCRIPT
