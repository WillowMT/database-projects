/* FITNESS CLUB -- Oracle Database 19c+ / Oracle APEX SQL Workshop
   Run once in a FRESH schema. No DROP statements and no SQL*Plus commands.
   Fictional data; currency THB. Authoring performed static validation only,
   not live Oracle execution. Exactly 10 tables. APEX application/Workbench excluded. */

-- 1. TABLES ---------------------------------------------------------
CREATE TABLE members (
 member_id NUMBER(6) CONSTRAINT pk_members PRIMARY KEY,
 full_name VARCHAR2(100) NOT NULL,
 email VARCHAR2(120) NOT NULL CONSTRAINT uq_members_email UNIQUE,
 phone VARCHAR2(25),
 birth_date DATE NOT NULL,
 member_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 joined_on DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
 CONSTRAINT ck_member_birth CHECK (birth_date BETWEEN DATE '1900-01-01' AND DATE '2020-12-31'),
 CONSTRAINT ck_member_status CHECK (member_status IN ('ACTIVE','INACTIVE'))
);
CREATE TABLE member_profiles (
 member_id NUMBER(6) CONSTRAINT pk_member_profiles PRIMARY KEY
  CONSTRAINT fk_profile_member REFERENCES members(member_id) ON DELETE CASCADE,
 emergency_name VARCHAR2(100) NOT NULL,
 emergency_phone VARCHAR2(25) NOT NULL,
 preferred_contact VARCHAR2(10) DEFAULT 'EMAIL' NOT NULL,
 CONSTRAINT ck_profile_contact CHECK (preferred_contact IN ('EMAIL','PHONE'))
);
CREATE TABLE membership_plans (
 plan_id NUMBER(6) CONSTRAINT pk_membership_plans PRIMARY KEY,
 plan_name VARCHAR2(50) NOT NULL CONSTRAINT uq_plan_name UNIQUE,
 duration_months NUMBER(2) NOT NULL,
 list_price NUMBER(10,2) NOT NULL,
 visits_per_week NUMBER(2),
 plan_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_plan_duration CHECK (duration_months BETWEEN 1 AND 24),
 CONSTRAINT ck_plan_price CHECK (list_price > 0),
 CONSTRAINT ck_plan_visits CHECK (visits_per_week IS NULL OR visits_per_week BETWEEN 1 AND 7),
 CONSTRAINT ck_plan_status CHECK (plan_status IN ('ACTIVE','RETIRED'))
);
CREATE TABLE memberships (
 membership_id NUMBER(6) CONSTRAINT pk_memberships PRIMARY KEY,
 member_id NUMBER(6) NOT NULL CONSTRAINT fk_membership_member REFERENCES members(member_id),
 plan_id NUMBER(6) NOT NULL CONSTRAINT fk_membership_plan REFERENCES membership_plans(plan_id),
 start_date DATE NOT NULL,
 end_date DATE NOT NULL,
 booked_price NUMBER(10,2) NOT NULL,
 membership_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_membership_dates CHECK (end_date > start_date),
 CONSTRAINT ck_membership_price CHECK (booked_price > 0),
 CONSTRAINT ck_membership_status CHECK (membership_status IN ('ACTIVE','EXPIRED','CANCELLED'))
);
CREATE TABLE trainers (
 trainer_id NUMBER(6) CONSTRAINT pk_trainers PRIMARY KEY,
 full_name VARCHAR2(100) NOT NULL,
 email VARCHAR2(120) NOT NULL CONSTRAINT uq_trainers_email UNIQUE,
 specialty VARCHAR2(60) NOT NULL,
 trainer_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_trainer_status CHECK (trainer_status IN ('ACTIVE','INACTIVE'))
);
CREATE TABLE studios (
 studio_id NUMBER(6) CONSTRAINT pk_studios PRIMARY KEY,
 studio_name VARCHAR2(50) NOT NULL CONSTRAINT uq_studio_name UNIQUE,
 capacity NUMBER(4) NOT NULL,
 studio_status VARCHAR2(12) DEFAULT 'OPEN' NOT NULL,
 CONSTRAINT ck_studio_capacity CHECK (capacity BETWEEN 1 AND 200),
 CONSTRAINT ck_studio_status CHECK (studio_status IN ('OPEN','CLOSED'))
);
CREATE TABLE class_types (
 class_type_id NUMBER(6) CONSTRAINT pk_class_types PRIMARY KEY,
 type_name VARCHAR2(60) NOT NULL CONSTRAINT uq_class_type_name UNIQUE,
 default_minutes NUMBER(3) NOT NULL,
 list_fee NUMBER(10,2) DEFAULT 0 NOT NULL,
 class_status VARCHAR2(12) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_class_minutes CHECK (default_minutes BETWEEN 15 AND 240),
 CONSTRAINT ck_class_fee CHECK (list_fee >= 0),
 CONSTRAINT ck_class_status CHECK (class_status IN ('ACTIVE','RETIRED'))
);
CREATE TABLE class_sessions (
 session_id NUMBER(6) CONSTRAINT pk_class_sessions PRIMARY KEY,
 class_type_id NUMBER(6) NOT NULL CONSTRAINT fk_session_class_type REFERENCES class_types(class_type_id),
 trainer_id NUMBER(6) CONSTRAINT fk_session_trainer REFERENCES trainers(trainer_id) ON DELETE SET NULL,
 studio_id NUMBER(6) NOT NULL CONSTRAINT fk_session_studio REFERENCES studios(studio_id),
 starts_at DATE NOT NULL,
 ends_at DATE NOT NULL,
 session_status VARCHAR2(12) DEFAULT 'SCHEDULED' NOT NULL,
 CONSTRAINT ck_session_dates CHECK (ends_at > starts_at),
 CONSTRAINT ck_session_status CHECK (session_status IN ('SCHEDULED','COMPLETED','CANCELLED'))
);
CREATE TABLE class_bookings (
 booking_id NUMBER(6) CONSTRAINT pk_class_bookings PRIMARY KEY,
 session_id NUMBER(6) NOT NULL CONSTRAINT fk_booking_session REFERENCES class_sessions(session_id) ON DELETE CASCADE,
 member_id NUMBER(6) NOT NULL CONSTRAINT fk_booking_member REFERENCES members(member_id),
 booked_at DATE DEFAULT SYSDATE NOT NULL,
 booking_status VARCHAR2(12) DEFAULT 'BOOKED' NOT NULL,
 CONSTRAINT uq_booking_member_session UNIQUE (session_id,member_id),
 CONSTRAINT ck_booking_status CHECK (booking_status IN ('BOOKED','CANCELLED','ATTENDED'))
);
CREATE TABLE payments (
 payment_id NUMBER(6) CONSTRAINT pk_payments PRIMARY KEY,
 membership_id NUMBER(6) NOT NULL CONSTRAINT fk_payment_membership REFERENCES memberships(membership_id),
 installment_no NUMBER(3) NOT NULL,
 paid_on DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
 amount NUMBER(10,2) NOT NULL,
 payment_method VARCHAR2(12) NOT NULL,
 payment_reference VARCHAR2(60) NOT NULL CONSTRAINT uq_payment_reference UNIQUE,
 CONSTRAINT uq_payment_installment UNIQUE (membership_id,installment_no),
 CONSTRAINT ck_payment_installment CHECK (installment_no >= 1),
 CONSTRAINT ck_payment_amount CHECK (amount > 0),
 CONSTRAINT ck_payment_method CHECK (payment_method IN ('CASH','CARD','TRANSFER'))
);
-- CASCADE only removes an optional profile or session bookings with its parent.
-- SET NULL retains a scheduled session if a trainer record is removed.
-- Restrictive membership/payment FKs preserve financial history.
CREATE INDEX ix_memberships_member ON memberships(member_id);
CREATE INDEX ix_memberships_plan ON memberships(plan_id);
CREATE INDEX ix_sessions_type ON class_sessions(class_type_id);
CREATE INDEX ix_sessions_trainer ON class_sessions(trainer_id);
CREATE INDEX ix_sessions_studio ON class_sessions(studio_id);
CREATE INDEX ix_bookings_member ON class_bookings(member_id);
CREATE INDEX ix_payments_membership ON payments(membership_id);

-- 2. MASTER/REFERENCE DATA (at least five each) --------------------
INSERT ALL
 INTO members VALUES (1,'Anan Suri','anan@fitness.example','0811111001',DATE '1991-03-10','ACTIVE',DATE '2025-01-05')
 INTO members VALUES (2,'Maya Chen','maya@fitness.example','0811111002',DATE '1988-08-21','ACTIVE',DATE '2025-02-10')
 INTO members VALUES (3,'James Wilson','james@fitness.example','0811111003',DATE '1994-01-14','ACTIVE',DATE '2025-03-01')
 INTO members VALUES (4,'Sofia Rossi','sofia@fitness.example','0811111004',DATE '1990-07-09','ACTIVE',DATE '2025-03-20')
 INTO members VALUES (5,'Min Thu','min@fitness.example','0811111005',DATE '1985-11-30','INACTIVE',DATE '2025-04-02')
 INTO members VALUES (6,'Yuki Sato','yuki@fitness.example','0811111006',DATE '1996-05-18','ACTIVE',DATE '2025-04-15')
 INTO members VALUES (7,'Lina Park','lina@fitness.example','0811111007',DATE '1992-02-28','ACTIVE',DATE '2025-05-01')
 INTO members VALUES (8,'Noah Brown','noah@fitness.example','0811111008',DATE '1987-09-12','ACTIVE',DATE '2025-05-16')
 INTO members VALUES (9,'Emma Martin','emma@fitness.example','0811111009',DATE '1993-12-04','ACTIVE',DATE '2025-06-01')
 INTO members VALUES (10,'Niran Chai','niran@fitness.example','0811111010',DATE '1989-06-25','ACTIVE',DATE '2025-06-12')
SELECT 1 FROM dual;
INSERT ALL
 INTO membership_plans VALUES (1,'Starter Monthly',1,1200,3,'ACTIVE')
 INTO membership_plans VALUES (2,'Unlimited Monthly',1,1800,NULL,'ACTIVE')
 INTO membership_plans VALUES (3,'Quarterly Plus',3,4800,5,'ACTIVE')
 INTO membership_plans VALUES (4,'Annual Access',12,16800,NULL,'ACTIVE')
 INTO membership_plans VALUES (5,'Student Monthly',1,900,3,'ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO trainers VALUES (1,'Pim Arun','pim@fitness.example','Yoga','ACTIVE')
 INTO trainers VALUES (2,'Somchai Dee','somchai@fitness.example','Strength','ACTIVE')
 INTO trainers VALUES (3,'Nok Suda','nok@fitness.example','Pilates','ACTIVE')
 INTO trainers VALUES (4,'Kanya Lek','kanya@fitness.example','Cycling','ACTIVE')
 INTO trainers VALUES (5,'Arun Wichai','arun@fitness.example','HIIT','ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO studios VALUES (1,'Lotus Studio',20,'OPEN')
 INTO studios VALUES (2,'Iron Hall',30,'OPEN')
 INTO studios VALUES (3,'Pulse Room',18,'OPEN')
 INTO studios VALUES (4,'Cycle Bay',25,'OPEN')
 INTO studios VALUES (5,'Sky Deck',15,'OPEN')
SELECT 1 FROM dual;
INSERT ALL
 INTO class_types VALUES (1,'Morning Yoga',60,150,'ACTIVE')
 INTO class_types VALUES (2,'Strength Basics',60,200,'ACTIVE')
 INTO class_types VALUES (3,'Pilates Core',45,180,'ACTIVE')
 INTO class_types VALUES (4,'Spin Express',45,180,'ACTIVE')
 INTO class_types VALUES (5,'HIIT Circuit',45,220,'ACTIVE')
SELECT 1 FROM dual;
-- 10 optional 1:1 profiles; no health/medical screening is stored or implied.
INSERT ALL
 INTO member_profiles VALUES (1,'Nok Suri','0815551001','PHONE')
 INTO member_profiles VALUES (2,'Li Chen','0815551002','EMAIL')
 INTO member_profiles VALUES (3,'Helen Wilson','0815551003','PHONE')
 INTO member_profiles VALUES (4,'Marco Rossi','0815551004','EMAIL')
 INTO member_profiles VALUES (5,'Thiri Thu','0815551005','PHONE')
 INTO member_profiles VALUES (6,'Ken Sato','0815551006','EMAIL')
 INTO member_profiles VALUES (7,'Jin Park','0815551007','PHONE')
 INTO member_profiles VALUES (8,'Olivia Brown','0815551008','EMAIL')
 INTO member_profiles VALUES (9,'Luc Martin','0815551009','PHONE')
 INTO member_profiles VALUES (10,'Dao Chai','0815551010','EMAIL')
SELECT 1 FROM dual;

-- 3. DETAIL DATA: ten memberships, ten valid sessions/bookings/payments
INSERT ALL
 INTO memberships VALUES (1,1,1,DATE '2026-01-01',DATE '2026-02-01',1200,'EXPIRED')
 INTO memberships VALUES (2,2,2,DATE '2026-01-05',DATE '2026-02-05',1750,'EXPIRED')
 INTO memberships VALUES (3,3,3,DATE '2026-02-01',DATE '2026-05-01',4600,'ACTIVE')
 INTO memberships VALUES (4,4,1,DATE '2026-02-10',DATE '2026-03-10',1200,'EXPIRED')
 INTO memberships VALUES (5,5,5,DATE '2026-03-01',DATE '2026-04-01',850,'CANCELLED')
 INTO memberships VALUES (6,6,4,DATE '2026-01-01',DATE '2027-01-01',16000,'ACTIVE')
 INTO memberships VALUES (7,7,2,DATE '2026-03-15',DATE '2026-04-15',1800,'EXPIRED')
 INTO memberships VALUES (8,8,3,DATE '2026-04-01',DATE '2026-07-01',4800,'ACTIVE')
 INTO memberships VALUES (9,9,1,DATE '2026-04-10',DATE '2026-05-10',1150,'EXPIRED')
 INTO memberships VALUES (10,10,5,DATE '2026-05-01',DATE '2026-06-01',900,'EXPIRED')
SELECT 1 FROM dual;
INSERT ALL
 INTO class_sessions VALUES (1,1,1,1,DATE '2026-01-06'+8/24,DATE '2026-01-06'+9/24,'COMPLETED')
 INTO class_sessions VALUES (2,2,2,2,DATE '2026-01-07'+18/24,DATE '2026-01-07'+19/24,'COMPLETED')
 INTO class_sessions VALUES (3,3,3,3,DATE '2026-02-03'+8/24,DATE '2026-02-03'+(8*60+45)/1440,'COMPLETED')
 INTO class_sessions VALUES (4,4,4,4,DATE '2026-02-04'+18/24,DATE '2026-02-04'+(18*60+45)/1440,'COMPLETED')
 INTO class_sessions VALUES (5,5,5,5,DATE '2026-03-03'+7/24,DATE '2026-03-03'+(7*60+45)/1440,'COMPLETED')
 INTO class_sessions VALUES (6,1,1,1,DATE '2026-03-10'+8/24,DATE '2026-03-10'+9/24,'COMPLETED')
 INTO class_sessions VALUES (7,2,2,2,DATE '2026-04-07'+18/24,DATE '2026-04-07'+19/24,'COMPLETED')
 INTO class_sessions VALUES (8,3,3,3,DATE '2026-04-08'+8/24,DATE '2026-04-08'+(8*60+45)/1440,'COMPLETED')
 INTO class_sessions VALUES (9,4,4,4,DATE '2026-05-05'+18/24,DATE '2026-05-05'+(18*60+45)/1440,'COMPLETED')
 INTO class_sessions VALUES (10,5,5,5,DATE '2026-05-06'+7/24,DATE '2026-05-06'+(7*60+45)/1440,'COMPLETED')
SELECT 1 FROM dual;
INSERT ALL
 INTO class_bookings VALUES (1,1,1,DATE '2026-01-02','ATTENDED')
 INTO class_bookings VALUES (2,2,2,DATE '2026-01-02','ATTENDED')
 INTO class_bookings VALUES (3,3,3,DATE '2026-01-29','ATTENDED')
 INTO class_bookings VALUES (4,4,4,DATE '2026-01-30','ATTENDED')
 INTO class_bookings VALUES (5,5,6,DATE '2026-02-27','ATTENDED')
 INTO class_bookings VALUES (6,6,7,DATE '2026-03-02','ATTENDED')
 INTO class_bookings VALUES (7,7,8,DATE '2026-04-01','ATTENDED')
 INTO class_bookings VALUES (8,8,9,DATE '2026-04-02','ATTENDED')
 INTO class_bookings VALUES (9,9,10,DATE '2026-04-28','ATTENDED')
 INTO class_bookings VALUES (10,10,3,DATE '2026-05-01','ATTENDED')
SELECT 1 FROM dual;
INSERT ALL
 INTO payments VALUES (1,1,1,DATE '2026-01-01',1200,'CARD','PAY-001')
 INTO payments VALUES (2,2,1,DATE '2026-01-05',1750,'CARD','PAY-002')
 INTO payments VALUES (3,3,1,DATE '2026-02-01',2300,'TRANSFER','PAY-003')
 INTO payments VALUES (4,4,1,DATE '2026-02-10',1200,'CASH','PAY-004')
 INTO payments VALUES (5,5,1,DATE '2026-03-01',400,'CASH','PAY-005')
 INTO payments VALUES (6,6,1,DATE '2026-01-01',8000,'TRANSFER','PAY-006')
 INTO payments VALUES (7,7,1,DATE '2026-03-15',1800,'CARD','PAY-007')
 INTO payments VALUES (8,8,1,DATE '2026-04-01',2400,'TRANSFER','PAY-008')
 INTO payments VALUES (9,9,1,DATE '2026-04-10',1150,'CARD','PAY-009')
 INTO payments VALUES (10,10,1,DATE '2026-05-01',900,'CASH','PAY-010')
SELECT 1 FROM dual;
COMMIT;

-- 4. VIEWS: independent payment preaggregation prevents aggregate fanout.
CREATE OR REPLACE VIEW v_membership_balance AS
SELECT ms.membership_id,m.full_name,p.plan_name,ms.start_date,ms.end_date,
 ms.membership_status,ms.booked_price,NVL(x.paid_total,0) paid_total,
 ms.booked_price-NVL(x.paid_total,0) balance_due
FROM memberships ms JOIN members m ON m.member_id=ms.member_id
JOIN membership_plans p ON p.plan_id=ms.plan_id
LEFT JOIN (SELECT membership_id,SUM(amount) paid_total FROM payments GROUP BY membership_id) x
 ON x.membership_id=ms.membership_id;
CREATE OR REPLACE VIEW v_class_session_summary AS
SELECT s.session_id,ct.type_name,st.studio_name,t.full_name trainer_name,s.starts_at,s.ends_at,
 s.session_status,COUNT(b.booking_id) booking_count,
 SUM(CASE WHEN b.booking_status='ATTENDED' THEN 1 ELSE 0 END) attended_count
FROM class_sessions s JOIN class_types ct ON ct.class_type_id=s.class_type_id
JOIN studios st ON st.studio_id=s.studio_id LEFT JOIN trainers t ON t.trainer_id=s.trainer_id
LEFT JOIN class_bookings b ON b.session_id=s.session_id
GROUP BY s.session_id,ct.type_name,st.studio_name,t.full_name,s.starts_at,s.ends_at,s.session_status;
CREATE OR REPLACE VIEW v_top5_members_by_paid AS
SELECT member_id,full_name,paid_total FROM (
 SELECT m.member_id,m.full_name,SUM(p.amount) paid_total
 FROM members m JOIN memberships ms ON ms.member_id=m.member_id
 JOIN payments p ON p.membership_id=ms.membership_id
 GROUP BY m.member_id,m.full_name ORDER BY paid_total DESC,m.member_id
) WHERE ROWNUM<=5;

-- 5. REQUIRED QUERIES ----------------------------------------------
-- Q1 JOIN: session roster/context, one row per booking.
SELECT b.booking_id,m.full_name,ct.type_name,st.studio_name,s.starts_at,b.booking_status
FROM class_bookings b JOIN members m ON m.member_id=b.member_id
JOIN class_sessions s ON s.session_id=b.session_id JOIN class_types ct ON ct.class_type_id=s.class_type_id
JOIN studios st ON st.studio_id=s.studio_id ORDER BY s.starts_at,b.booking_id;
-- Q2 GROUP BY/HAVING: members who booked at least two sessions.
SELECT m.member_id,m.full_name,COUNT(*) booking_count FROM members m JOIN class_bookings b ON b.member_id=m.member_id
GROUP BY m.member_id,m.full_name HAVING COUNT(*)>=2;
-- Q3 scalar subquery: balances higher than average membership balance.
SELECT membership_id,full_name,balance_due FROM v_membership_balance
WHERE balance_due>(SELECT AVG(balance_due) FROM v_membership_balance) ORDER BY balance_due DESC;
-- Q4 FROM subquery: instructors whose completed classes have bookings.
SELECT t.full_name,x.total_bookings FROM trainers t JOIN (
 SELECT s.trainer_id,COUNT(b.booking_id) total_bookings FROM class_sessions s JOIN class_bookings b ON b.session_id=s.session_id
 WHERE s.session_status='COMPLETED' GROUP BY s.trainer_id
) x ON x.trainer_id=t.trainer_id WHERE x.total_bookings>=1 ORDER BY x.total_bookings DESC;
-- Q5 Top-N: sorted inline view then ROWNUM outside.
SELECT * FROM (SELECT membership_id,full_name,balance_due FROM v_membership_balance ORDER BY balance_due DESC,membership_id) WHERE ROWNUM<=5;
-- Q6 ROLLUP/GROUPING: paid revenue by plan and membership status.
SELECT CASE WHEN GROUPING(plan_name)=1 THEN 'ALL PLANS' ELSE plan_name END plan_name,
 CASE WHEN GROUPING(membership_status)=1 THEN 'ALL STATUSES' ELSE membership_status END membership_status,
 SUM(paid_total) paid_revenue,GROUPING(plan_name) plan_grouped,GROUPING(membership_status) status_grouped
FROM v_membership_balance GROUP BY ROLLUP(plan_name,membership_status)
ORDER BY GROUPING(plan_name),plan_name,GROUPING(membership_status),membership_status;
SELECT * FROM v_class_session_summary ORDER BY starts_at;
SELECT * FROM v_top5_members_by_paid ORDER BY paid_total DESC,member_id;

-- 6. DML / TRANSACTIONS --------------------------------------------
INSERT INTO members (member_id,full_name,email,birth_date) VALUES (900001,'Transaction Demo','transaction@fitness.example',DATE '1995-01-01');
COMMIT;
UPDATE members SET full_name='Uncommitted Name' WHERE member_id=900001;
ROLLBACK;
SELECT full_name,member_status FROM members WHERE member_id=900001;
DELETE FROM members m WHERE m.member_id=900001 AND NOT EXISTS (SELECT 1 FROM memberships ms WHERE ms.member_id=m.member_id);
COMMIT;
SAVEPOINT rate_demo;
UPDATE membership_plans SET list_price=list_price*1.05 WHERE plan_id IN (SELECT plan_id FROM memberships WHERE membership_status='ACTIVE');
ROLLBACK TO rate_demo;
COMMIT;

-- 7. ROLLBACK-SAFE EXPECTED ERROR TESTS ---------------------------
DECLARE
 PROCEDURE expect_error(p_label VARCHAR2,p_sql VARCHAR2,p_expected NUMBER) IS v_code NUMBER;
 BEGIN SAVEPOINT test_case; BEGIN EXECUTE IMMEDIATE p_sql;
 EXCEPTION WHEN OTHERS THEN v_code:=SQLCODE; ROLLBACK TO test_case;
  IF v_code=p_expected THEN DBMS_OUTPUT.PUT_LINE('PASS: '||p_label||' SQLCODE '||v_code); RETURN; END IF; RAISE; END;
 ROLLBACK TO test_case; RAISE_APPLICATION_ERROR(-20001,'FAIL: '||p_label||' unexpectedly succeeded); END;
BEGIN
 expect_error('duplicate member PK',q'[INSERT INTO members VALUES (1,'X','x1@fitness.example',NULL,DATE '1995-01-01','ACTIVE',DATE '2026-01-01')]',-1);
 expect_error('duplicate member email',q'[INSERT INTO members VALUES (900002,'X','anan@fitness.example',NULL,DATE '1995-01-01','ACTIVE',DATE '2026-01-01')]',-1);
 expect_error('missing member name',q'[INSERT INTO members VALUES (900002,NULL,'x2@fitness.example',NULL,DATE '1995-01-01','ACTIVE',DATE '2026-01-01')]',-1400);
 expect_error('invalid birth date',q'[UPDATE members SET birth_date=DATE '1880-01-01' WHERE member_id=1]',-2290);
 expect_error('membership date order',q'[UPDATE memberships SET end_date=start_date WHERE membership_id=1]',-2290);
 expect_error('payment membership FK',q'[INSERT INTO payments VALUES (900002,999999,1,DATE '2026-01-01',1,'CASH','BAD-FK')]',-2291);
 expect_error('duplicate session booking',q'[INSERT INTO class_bookings VALUES (900002,1,1,DATE '2026-01-01','BOOKED')]',-1);
 expect_error('payment protects membership',q'[DELETE FROM memberships WHERE membership_id=1]',-2292);
END;
/
-- Referencing actions: test SET NULL and CASCADE, then restore all changes.
DECLARE v_count NUMBER;
BEGIN
 SAVEPOINT actions_test;
 INSERT INTO trainers VALUES (900003,'Temporary Trainer','temp@fitness.example','Demo','ACTIVE');
 INSERT INTO class_sessions VALUES (900003,1,900003,1,DATE '2026-06-01'+8/24,DATE '2026-06-01'+9/24,'SCHEDULED');
 INSERT INTO class_bookings VALUES (900003,900003,1,DATE '2026-05-30','BOOKED');
 DELETE FROM trainers WHERE trainer_id=900003;
 SELECT COUNT(*) INTO v_count FROM class_sessions WHERE session_id=900003 AND trainer_id IS NULL;
 IF v_count<>1 THEN RAISE_APPLICATION_ERROR(-20002,'SET NULL failed'); END IF;
 DELETE FROM class_sessions WHERE session_id=900003;
 SELECT COUNT(*) INTO v_count FROM class_bookings WHERE session_id=900003;
 IF v_count<>0 THEN RAISE_APPLICATION_ERROR(-20003,'CASCADE failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: SET NULL and CASCADE'); ROLLBACK TO actions_test;
EXCEPTION WHEN OTHERS THEN ROLLBACK TO actions_test; RAISE; END;
/
COMMIT;
-- Expected audit: 10 rows in every table. These diagnostics should return zero rows.
SELECT 'MEMBERS' table_name,COUNT(*) row_count FROM members UNION ALL SELECT 'MEMBER_PROFILES',COUNT(*) FROM member_profiles UNION ALL SELECT 'MEMBERSHIP_PLANS',COUNT(*) FROM membership_plans UNION ALL SELECT 'MEMBERSHIPS',COUNT(*) FROM memberships UNION ALL SELECT 'TRAINERS',COUNT(*) FROM trainers UNION ALL SELECT 'STUDIOS',COUNT(*) FROM studios UNION ALL SELECT 'CLASS_TYPES',COUNT(*) FROM class_types UNION ALL SELECT 'CLASS_SESSIONS',COUNT(*) FROM class_sessions UNION ALL SELECT 'CLASS_BOOKINGS',COUNT(*) FROM class_bookings UNION ALL SELECT 'PAYMENTS',COUNT(*) FROM payments;
SELECT membership_id,balance_due FROM v_membership_balance WHERE balance_due<0;
-- Capacity, active-membership eligibility and instructor/studio schedule conflicts are documented application/procedure checks, not fully DB-enforced cross-row rules.

-- 8. OPTIONAL SECURITY (FALSE for hosted APEX) ---------------------
DECLARE c_enable_security CONSTANT BOOLEAN:=FALSE; BEGIN IF c_enable_security THEN
 EXECUTE IMMEDIATE 'CREATE ROLE fc_reception'; EXECUTE IMMEDIATE 'CREATE ROLE fc_manager';
 EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON members TO fc_reception';
 EXECUTE IMMEDIATE 'GRANT SELECT ON v_class_session_summary TO fc_reception';
 EXECUTE IMMEDIATE 'GRANT fc_reception TO fc_manager'; EXECUTE IMMEDIATE 'GRANT SELECT ON v_membership_balance TO fc_manager';
 ELSE DBMS_OUTPUT.PUT_LINE('NOT RUN: roles/GRANT require DBA approval; hosted APEX flag is FALSE.'); END IF; END;
/
-- END OF SCRIPT
