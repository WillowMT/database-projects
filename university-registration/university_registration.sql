/* UNIVERSITY REGISTRATION -- Oracle Database 19c+ / APEX SQL Workshop
   Run once in a FRESH schema. No destructive reset and no SQL*Plus commands.
   Academic model: exactly 10 tables; all sample identities are fictional.
   Not executed against an Oracle instance during artifact preparation.
   DDL commits implicitly in Oracle; a failed run can leave prior objects created.
   Scope limits: capacity, timetable clashes, prerequisites, course-repeat rules,
   term-date membership and installment ceilings require controlled PL/SQL/API logic.
   No APEX application or MySQL Workbench artifact is included.
*/

-- 1. TABLES AND CONSTRAINTS -----------------------------------------
CREATE TABLE departments (
 department_id NUMBER(6) CONSTRAINT pk_departments PRIMARY KEY,
 department_code VARCHAR2(10) NOT NULL CONSTRAINT uq_department_code UNIQUE,
 department_name VARCHAR2(100) NOT NULL CONSTRAINT uq_department_name UNIQUE,
 office_phone VARCHAR2(25)
);
CREATE TABLE programs (
 program_id NUMBER(6) CONSTRAINT pk_programs PRIMARY KEY,
 department_id NUMBER(6) NOT NULL CONSTRAINT fk_program_department REFERENCES departments(department_id),
 program_code VARCHAR2(15) NOT NULL CONSTRAINT uq_program_code UNIQUE,
 program_name VARCHAR2(120) NOT NULL CONSTRAINT uq_program_name UNIQUE,
 award_level VARCHAR2(15) DEFAULT 'BACHELOR' NOT NULL,
 CONSTRAINT ck_program_award CHECK (award_level IN ('DIPLOMA','BACHELOR','MASTER'))
);
CREATE TABLE students (
 student_id NUMBER(8) CONSTRAINT pk_students PRIMARY KEY,
 program_id NUMBER(6) NOT NULL CONSTRAINT fk_student_program REFERENCES programs(program_id),
 student_number VARCHAR2(20) NOT NULL CONSTRAINT uq_student_number UNIQUE,
 full_name VARCHAR2(120) NOT NULL,
 university_email VARCHAR2(120) NOT NULL CONSTRAINT uq_student_email UNIQUE,
 admitted_on DATE NOT NULL,
 student_status VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_student_admitted CHECK (admitted_on = TRUNC(admitted_on)),
 CONSTRAINT ck_student_status CHECK (student_status IN ('ACTIVE','LEAVE','GRADUATED','WITHDRAWN'))
);
CREATE TABLE student_profiles (
 student_id NUMBER(8) CONSTRAINT pk_student_profiles PRIMARY KEY
   CONSTRAINT fk_profile_student REFERENCES students(student_id) ON DELETE CASCADE,
 birth_date DATE,
 mobile_phone VARCHAR2(25),
 emergency_contact VARCHAR2(120),
 consent_to_contact CHAR(1) DEFAULT 'Y' NOT NULL,
 CONSTRAINT ck_profile_birth_date CHECK (birth_date IS NULL OR birth_date < DATE '2010-01-01'),
 CONSTRAINT ck_profile_consent CHECK (consent_to_contact IN ('Y','N'))
);
CREATE TABLE instructors (
 instructor_id NUMBER(6) CONSTRAINT pk_instructors PRIMARY KEY,
 department_id NUMBER(6) NOT NULL CONSTRAINT fk_instructor_department REFERENCES departments(department_id),
 full_name VARCHAR2(120) NOT NULL,
 university_email VARCHAR2(120) NOT NULL CONSTRAINT uq_instructor_email UNIQUE,
 employment_status VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL,
 CONSTRAINT ck_instructor_status CHECK (employment_status IN ('ACTIVE','ON_LEAVE','INACTIVE'))
);
CREATE TABLE courses (
 course_id NUMBER(6) CONSTRAINT pk_courses PRIMARY KEY,
 department_id NUMBER(6) NOT NULL CONSTRAINT fk_course_department REFERENCES departments(department_id),
 course_code VARCHAR2(15) NOT NULL CONSTRAINT uq_course_code UNIQUE,
 course_title VARCHAR2(150) NOT NULL,
 credits NUMBER(2) NOT NULL,
 current_tuition NUMBER(10,2) NOT NULL,
 CONSTRAINT ck_course_credits CHECK (credits BETWEEN 1 AND 6),
 CONSTRAINT ck_course_tuition CHECK (current_tuition > 0)
);
CREATE TABLE terms (
 term_id NUMBER(6) CONSTRAINT pk_terms PRIMARY KEY,
 term_code VARCHAR2(15) NOT NULL CONSTRAINT uq_term_code UNIQUE,
 term_name VARCHAR2(80) NOT NULL,
 starts_on DATE NOT NULL,
 ends_on DATE NOT NULL,
 term_status VARCHAR2(15) DEFAULT 'PLANNED' NOT NULL,
 CONSTRAINT ck_term_dates CHECK (ends_on > starts_on),
 CONSTRAINT ck_term_midnight CHECK (starts_on = TRUNC(starts_on) AND ends_on = TRUNC(ends_on)),
 CONSTRAINT ck_term_status CHECK (term_status IN ('PLANNED','OPEN','CLOSED'))
);
CREATE TABLE sections (
 section_id NUMBER(8) CONSTRAINT pk_sections PRIMARY KEY,
 course_id NUMBER(6) NOT NULL CONSTRAINT fk_section_course REFERENCES courses(course_id),
 term_id NUMBER(6) NOT NULL CONSTRAINT fk_section_term REFERENCES terms(term_id),
 instructor_id NUMBER(6) CONSTRAINT fk_section_instructor REFERENCES instructors(instructor_id) ON DELETE SET NULL,
 section_code VARCHAR2(10) NOT NULL,
 delivery_mode VARCHAR2(15) DEFAULT 'ON_CAMPUS' NOT NULL,
 section_status VARCHAR2(15) DEFAULT 'OPEN' NOT NULL,
 CONSTRAINT uq_section_course_term_code UNIQUE (course_id,term_id,section_code),
 CONSTRAINT ck_section_delivery CHECK (delivery_mode IN ('ON_CAMPUS','ONLINE','HYBRID')),
 CONSTRAINT ck_section_status CHECK (section_status IN ('OPEN','CLOSED','CANCELLED'))
);
CREATE TABLE enrollments (
 enrollment_id NUMBER(8) CONSTRAINT pk_enrollments PRIMARY KEY,
 student_id NUMBER(8) NOT NULL CONSTRAINT fk_enrollment_student REFERENCES students(student_id),
 section_id NUMBER(8) NOT NULL CONSTRAINT fk_enrollment_section REFERENCES sections(section_id),
 enrolled_on DATE DEFAULT SYSDATE NOT NULL,
 enrollment_status VARCHAR2(15) DEFAULT 'ENROLLED' NOT NULL,
 booked_tuition NUMBER(10,2) NOT NULL,
 final_grade VARCHAR2(2),
 CONSTRAINT uq_enrollment_student_section UNIQUE (student_id,section_id),
 CONSTRAINT ck_enrollment_date CHECK (enrolled_on = TRUNC(enrolled_on)),
 CONSTRAINT ck_enrollment_status CHECK (enrollment_status IN ('ENROLLED','COMPLETED','DROPPED')),
 CONSTRAINT ck_booked_tuition CHECK (booked_tuition > 0),
 CONSTRAINT ck_final_grade CHECK (final_grade IS NULL OR final_grade IN ('A','B+','B','C+','C','D+','D','F','W'))
);
CREATE TABLE payments (
 payment_id NUMBER(8) CONSTRAINT pk_payments PRIMARY KEY,
 enrollment_id NUMBER(8) NOT NULL CONSTRAINT fk_payment_enrollment REFERENCES enrollments(enrollment_id),
 paid_on DATE DEFAULT SYSDATE NOT NULL,
 amount NUMBER(10,2) NOT NULL,
 payment_method VARCHAR2(15) NOT NULL,
 payment_reference VARCHAR2(60) NOT NULL CONSTRAINT uq_payment_reference UNIQUE,
 CONSTRAINT ck_payment_date CHECK (paid_on = TRUNC(paid_on)),
 CONSTRAINT ck_payment_amount CHECK (amount > 0),
 CONSTRAINT ck_payment_method CHECK (payment_method IN ('CARD','TRANSFER','CASH','SCHOLARSHIP'))
);

-- CASCADE removes a dependent optional profile with its student identity.
-- SET NULL preserves a section record if its instructor record is removed.
-- Restrictive enrollment/payment FKs preserve tuition receipt history.
CREATE INDEX ix_program_department ON programs(department_id);
CREATE INDEX ix_student_program ON students(program_id);
CREATE INDEX ix_instructor_department ON instructors(department_id);
CREATE INDEX ix_course_department ON courses(department_id);
CREATE INDEX ix_section_term ON sections(term_id);
CREATE INDEX ix_section_instructor ON sections(instructor_id);
CREATE INDEX ix_enrollment_section ON enrollments(section_id);
CREATE INDEX ix_payment_enrollment ON payments(enrollment_id);

-- 2. MASTER / REFERENCE DATA ----------------------------------------
INSERT ALL
 INTO departments VALUES (1,'COMP','School of Computing','02-100-1001')
 INTO departments VALUES (2,'BUS','School of Business','02-100-1002')
 INTO departments VALUES (3,'ENG','School of Engineering','02-100-1003')
 INTO departments VALUES (4,'ARTS','School of Arts and Communication','02-100-1004')
 INTO departments VALUES (5,'SCI','School of Science','02-100-1005')
SELECT 1 FROM dual;
INSERT ALL
 INTO programs VALUES (1,1,'BSC-CS','Bachelor of Science in Computer Science','BACHELOR')
 INTO programs VALUES (2,2,'BBA','Bachelor of Business Administration','BACHELOR')
 INTO programs VALUES (3,3,'BENG-EE','Bachelor of Engineering in Electrical Engineering','BACHELOR')
 INTO programs VALUES (4,4,'BA-COMM','Bachelor of Arts in Communication','BACHELOR')
 INTO programs VALUES (5,5,'BSC-DS','Bachelor of Science in Data Science','BACHELOR')
SELECT 1 FROM dual;
INSERT ALL
 INTO instructors VALUES (1,1,'Dr Naree Kittisak','naree.kittisak@university.example','ACTIVE')
 INTO instructors VALUES (2,2,'Assoc Prof Daniel Lim','daniel.lim@university.example','ACTIVE')
 INTO instructors VALUES (3,3,'Dr Ploy Anurak','ploy.anurak@university.example','ACTIVE')
 INTO instructors VALUES (4,4,'Dr Mira Santos','mira.santos@university.example','ACTIVE')
 INTO instructors VALUES (5,5,'Dr Arun Mehta','arun.mehta@university.example','ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO courses VALUES (1,1,'CS101','Programming Fundamentals',3,18000)
 INTO courses VALUES (2,1,'CS220','Database Systems',3,19500)
 INTO courses VALUES (3,2,'BUS110','Principles of Management',3,17500)
 INTO courses VALUES (4,2,'BUS240','Marketing Analytics',3,19000)
 INTO courses VALUES (5,3,'EE101','Circuit Analysis I',3,20000)
 INTO courses VALUES (6,3,'EE230','Embedded Systems',3,21000)
 INTO courses VALUES (7,4,'COM101','Public Speaking',3,16500)
 INTO courses VALUES (8,4,'COM210','Digital Storytelling',3,18000)
 INTO courses VALUES (9,5,'DS101','Statistics for Data Science',3,19000)
 INTO courses VALUES (10,5,'DS250','Data Visualization',3,20000)
SELECT 1 FROM dual;
INSERT ALL
 INTO terms VALUES (1,'2025-SUM','Summer 2025',DATE '2025-06-02',DATE '2025-08-01','CLOSED')
 INTO terms VALUES (2,'2025-FALL','Fall 2025',DATE '2025-08-18',DATE '2025-12-12','CLOSED')
 INTO terms VALUES (3,'2026-SPR','Spring 2026',DATE '2026-01-12',DATE '2026-05-08','CLOSED')
 INTO terms VALUES (4,'2026-SUM','Summer 2026',DATE '2026-06-01',DATE '2026-07-31','OPEN')
 INTO terms VALUES (5,'2026-FALL','Fall 2026',DATE '2026-08-17',DATE '2026-12-11','PLANNED')
SELECT 1 FROM dual;

-- 3. DETAIL DATA: 10 students, profiles, sections, enrollments, installments
INSERT ALL
 INTO students VALUES (1,1,'68010001','Anan Suri','anan.suri@university.example',DATE '2025-08-18','ACTIVE')
 INTO students VALUES (2,5,'68010002','Maya Chen','maya.chen@university.example',DATE '2025-08-18','ACTIVE')
 INTO students VALUES (3,2,'68010003','James Wilson','james.wilson@university.example',DATE '2025-08-18','ACTIVE')
 INTO students VALUES (4,3,'68010004','Sofia Rossi','sofia.rossi@university.example',DATE '2025-08-18','ACTIVE')
 INTO students VALUES (5,4,'68010005','Min Thu','min.thu@university.example',DATE '2025-08-18','ACTIVE')
 INTO students VALUES (6,1,'68010006','Yuki Sato','yuki.sato@university.example',DATE '2026-01-12','ACTIVE')
 INTO students VALUES (7,5,'68010007','Lina Park','lina.park@university.example',DATE '2026-01-12','ACTIVE')
 INTO students VALUES (8,2,'68010008','Noah Brown','noah.brown@university.example',DATE '2026-01-12','ACTIVE')
 INTO students VALUES (9,3,'68010009','Emma Martin','emma.martin@university.example',DATE '2026-01-12','ACTIVE')
 INTO students VALUES (10,4,'68010010','Niran Chai','niran.chai@university.example',DATE '2026-01-12','ACTIVE')
SELECT 1 FROM dual;
INSERT ALL
 INTO student_profiles VALUES (1,DATE '2006-03-14','081-111-1001','Som Suri','Y')
 INTO student_profiles VALUES (2,DATE '2005-11-02','081-111-1002','Li Chen','Y')
 INTO student_profiles VALUES (3,DATE '2006-07-22','081-111-1003','Helen Wilson','N')
 INTO student_profiles VALUES (4,DATE '2005-01-19','081-111-1004','Marco Rossi','Y')
 INTO student_profiles VALUES (5,DATE '2006-09-08','081-111-1005','Aye Thu','Y')
 INTO student_profiles VALUES (6,DATE '2007-05-30','081-111-1006','Ken Sato','Y')
 INTO student_profiles VALUES (7,DATE '2006-12-11','081-111-1007','Jin Park','Y')
 INTO student_profiles VALUES (8,DATE '2007-02-16','081-111-1008','Olivia Brown','N')
 INTO student_profiles VALUES (9,DATE '2006-08-04','081-111-1009','Claire Martin','Y')
 INTO student_profiles VALUES (10,DATE '2007-01-25','081-111-1010','Chaiwat Chai','Y')
SELECT 1 FROM dual;
INSERT ALL
 INTO sections VALUES (1,1,3,1,'01','ON_CAMPUS','CLOSED')
 INTO sections VALUES (2,2,3,1,'01','HYBRID','CLOSED')
 INTO sections VALUES (3,3,3,2,'01','ON_CAMPUS','CLOSED')
 INTO sections VALUES (4,4,3,2,'01','ONLINE','CLOSED')
 INTO sections VALUES (5,5,3,3,'01','ON_CAMPUS','CLOSED')
 INTO sections VALUES (6,6,3,3,'01','HYBRID','CLOSED')
 INTO sections VALUES (7,7,4,4,'01','ON_CAMPUS','OPEN')
 INTO sections VALUES (8,8,4,4,'01','ONLINE','OPEN')
 INTO sections VALUES (9,9,4,5,'01','ON_CAMPUS','OPEN')
 INTO sections VALUES (10,10,4,5,'01','HYBRID','OPEN')
SELECT 1 FROM dual;
INSERT ALL
 INTO enrollments VALUES (1,1,1,DATE '2026-01-05','COMPLETED',18000,'A')
 INTO enrollments VALUES (2,1,2,DATE '2026-01-05','COMPLETED',19500,'B+')
 INTO enrollments VALUES (3,2,2,DATE '2026-01-06','COMPLETED',19500,'A')
 INTO enrollments VALUES (4,3,3,DATE '2026-01-06','COMPLETED',17500,'B')
 INTO enrollments VALUES (5,4,5,DATE '2026-01-07','COMPLETED',20000,'B+')
 INTO enrollments VALUES (6,5,4,DATE '2026-01-07','COMPLETED',19000,'A')
 INTO enrollments VALUES (7,6,7,DATE '2026-05-18','ENROLLED',16500,NULL)
 INTO enrollments VALUES (8,7,9,DATE '2026-05-18','ENROLLED',19000,NULL)
 INTO enrollments VALUES (9,8,8,DATE '2026-05-19','ENROLLED',18000,NULL)
 INTO enrollments VALUES (10,9,10,DATE '2026-05-19','ENROLLED',20000,NULL)
 INTO enrollments VALUES (11,10,7,DATE '2026-05-20','ENROLLED',16500,NULL)
 INTO enrollments VALUES (12,2,9,DATE '2026-05-20','ENROLLED',19000,NULL)
SELECT 1 FROM dual;
INSERT ALL
 INTO payments VALUES (1,1,DATE '2026-01-06',18000,'TRANSFER','PAY-2026-0001')
 INTO payments VALUES (2,2,DATE '2026-01-06',10000,'CARD','PAY-2026-0002')
 INTO payments VALUES (3,2,DATE '2026-02-06',9500,'TRANSFER','PAY-2026-0003')
 INTO payments VALUES (4,3,DATE '2026-01-08',19500,'SCHOLARSHIP','PAY-2026-0004')
 INTO payments VALUES (5,4,DATE '2026-01-08',17500,'TRANSFER','PAY-2026-0005')
 INTO payments VALUES (6,5,DATE '2026-01-09',20000,'CARD','PAY-2026-0006')
 INTO payments VALUES (7,6,DATE '2026-01-09',19000,'TRANSFER','PAY-2026-0007')
 INTO payments VALUES (8,7,DATE '2026-05-21',8000,'CARD','PAY-2026-0008')
 INTO payments VALUES (9,8,DATE '2026-05-21',10000,'TRANSFER','PAY-2026-0009')
 INTO payments VALUES (10,9,DATE '2026-05-22',9000,'CARD','PAY-2026-0010')
 INTO payments VALUES (11,10,DATE '2026-05-22',10000,'TRANSFER','PAY-2026-0011')
 INTO payments VALUES (12,12,DATE '2026-05-23',5000,'CASH','PAY-2026-0012')
SELECT 1 FROM dual;
COMMIT;

-- 4. VIEWS ----------------------------------------------------------
-- V1: operational multi-table view; one row per enrollment.
CREATE OR REPLACE VIEW v_enrollment_details AS
SELECT e.enrollment_id,s.student_number,s.full_name AS student_name,
       p.program_code,p.program_name,c.course_code,c.course_title,c.credits,
       t.term_code,sec.section_code,i.full_name AS instructor_name,
       e.enrolled_on,e.enrollment_status,e.booked_tuition,e.final_grade
FROM enrollments e
JOIN students s ON s.student_id=e.student_id
JOIN programs p ON p.program_id=s.program_id
JOIN sections sec ON sec.section_id=e.section_id
JOIN courses c ON c.course_id=sec.course_id
JOIN terms t ON t.term_id=sec.term_id
LEFT JOIN instructors i ON i.instructor_id=sec.instructor_id;

-- V2: tuition summary. Payments are preaggregated before joining, so a
-- multi-installment enrollment is never multiplied by its other joins.
CREATE OR REPLACE VIEW v_enrollment_balance AS
SELECT e.enrollment_id,e.student_id,e.section_id,e.booked_tuition,
       NVL(px.paid_total,0) AS paid_total,
       e.booked_tuition-NVL(px.paid_total,0) AS balance_due
FROM enrollments e
LEFT JOIN (
 SELECT enrollment_id,SUM(amount) AS paid_total
 FROM payments
 GROUP BY enrollment_id
) px ON px.enrollment_id=e.enrollment_id;

-- V3: Top-N students by booked tuition. Sorting occurs inside, ROWNUM outside.
CREATE OR REPLACE VIEW v_top5_students_by_tuition AS
SELECT student_id,student_name,total_booked_tuition
FROM (
 SELECT s.student_id,s.full_name AS student_name,SUM(b.booked_tuition) AS total_booked_tuition
 FROM students s JOIN v_enrollment_balance b ON b.student_id=s.student_id
 GROUP BY s.student_id,s.full_name
 ORDER BY total_booked_tuition DESC,s.student_id
)
WHERE ROWNUM <= 5;

-- 5. REQUIRED QUERIES ----------------------------------------------
-- Q1 JOIN ... ON: enrollment, program, course, term and instructor context.
SELECT * FROM v_enrollment_details ORDER BY term_code,course_code,student_number;

-- Q2 GROUP BY / HAVING: students registered in at least two sections.
SELECT s.student_id,s.full_name,COUNT(e.enrollment_id) AS section_count
FROM students s JOIN enrollments e ON e.student_id=s.student_id
GROUP BY s.student_id,s.full_name
HAVING COUNT(e.enrollment_id) >= 2
ORDER BY section_count DESC,s.student_id;

-- Q3 scalar subquery: enrollments whose booked tuition exceeds the average.
SELECT d.enrollment_id,d.student_name,d.course_code,d.booked_tuition
FROM v_enrollment_details d
WHERE d.booked_tuition > (SELECT AVG(booked_tuition) FROM enrollments)
ORDER BY d.booked_tuition DESC,d.enrollment_id;

-- Q4 FROM-clause subquery: students whose cumulative booked tuition exceeds THB 30,000.
SELECT s.student_number,s.full_name,x.total_booked_tuition
FROM students s JOIN (
 SELECT student_id,SUM(booked_tuition) AS total_booked_tuition
 FROM enrollments
 GROUP BY student_id
) x ON x.student_id=s.student_id
WHERE x.total_booked_tuition > 30000
ORDER BY x.total_booked_tuition DESC,s.student_id;

-- Q5 second FROM-clause subquery: sections with unpaid booked tuition.
SELECT q.term_code,q.course_code,q.section_code,q.booked_total,q.paid_total,q.balance_due
FROM (
 SELECT d.term_code,d.course_code,d.section_code,SUM(b.booked_tuition) AS booked_total,
        SUM(b.paid_total) AS paid_total,SUM(b.balance_due) AS balance_due
 FROM v_enrollment_details d JOIN v_enrollment_balance b ON b.enrollment_id=d.enrollment_id
 GROUP BY d.term_code,d.course_code,d.section_code
) q
WHERE q.balance_due > 0
ORDER BY q.balance_due DESC,q.course_code;

-- Q6 sorted inline view and ROWNUM: five largest tuition balances.
SELECT * FROM (
 SELECT d.student_name,d.course_code,b.balance_due
 FROM v_enrollment_details d JOIN v_enrollment_balance b ON b.enrollment_id=d.enrollment_id
 ORDER BY b.balance_due DESC,d.student_name,d.course_code
) WHERE ROWNUM <= 5;

-- Q7 ROLLUP / GROUPING: booked tuition by term and enrollment status.
SELECT CASE WHEN GROUPING(d.term_code)=1 THEN 'ALL TERMS' ELSE d.term_code END AS term_code,
       CASE WHEN GROUPING(d.enrollment_status)=1 THEN 'ALL STATUSES' ELSE d.enrollment_status END AS enrollment_status,
       SUM(d.booked_tuition) AS booked_tuition,
       GROUPING(d.term_code) AS term_grouped,GROUPING(d.enrollment_status) AS status_grouped
FROM v_enrollment_details d
GROUP BY ROLLUP(d.term_code,d.enrollment_status)
ORDER BY GROUPING(d.term_code),d.term_code,GROUPING(d.enrollment_status),d.enrollment_status;

SELECT * FROM v_enrollment_balance ORDER BY enrollment_id;
SELECT * FROM v_top5_students_by_tuition ORDER BY total_booked_tuition DESC,student_id;

-- 6. DML, CONDITIONAL SUBQUERY, COMMIT AND ROLLBACK -----------------
INSERT INTO students (student_id,program_id,student_number,full_name,university_email,admitted_on)
VALUES (900001,1,'DEMO-900001','Transaction Demo','transaction.demo@university.example',DATE '2026-05-25');
COMMIT;
UPDATE students SET full_name='Uncommitted Name' WHERE student_id=900001;
ROLLBACK;
SELECT full_name,student_status FROM students WHERE student_id=900001;
-- Expected: Transaction Demo; ACTIVE (DEFAULT demonstration).
DELETE FROM students s WHERE s.student_id=900001
AND NOT EXISTS (SELECT 1 FROM enrollments e WHERE e.student_id=s.student_id);
COMMIT;
SAVEPOINT before_tuition_demo;
UPDATE courses SET current_tuition=current_tuition*1.03
WHERE course_id IN (SELECT course_id FROM sections WHERE section_status='OPEN');
SELECT course_code,current_tuition FROM courses ORDER BY course_id;
ROLLBACK TO before_tuition_demo;
COMMIT;

-- 7. ROLLBACK-SAFE NEGATIVE TESTS -----------------------------------
DECLARE
 PROCEDURE expect_error(p_label VARCHAR2,p_sql VARCHAR2,p_expected NUMBER) IS
  v_code NUMBER;
 BEGIN
  SAVEPOINT test_case;
  BEGIN
   EXECUTE IMMEDIATE p_sql;
  EXCEPTION WHEN OTHERS THEN
   v_code:=SQLCODE; ROLLBACK TO test_case;
   IF v_code=p_expected THEN
    DBMS_OUTPUT.PUT_LINE('PASS: '||p_label||' (SQLCODE '||v_code||')'); RETURN;
   END IF;
   RAISE;
  END;
  ROLLBACK TO test_case;
  RAISE_APPLICATION_ERROR(-20001,'FAIL: '||p_label||' unexpectedly succeeded');
 END;
BEGIN
 expect_error('Duplicate student primary key',q'[INSERT INTO students VALUES (1,1,'TEST-PK','Test','test.pk@university.example',DATE '2026-01-01','ACTIVE')]',-1);
 expect_error('Unique enrollment per student and section',q'[INSERT INTO enrollments VALUES (900002,1,1,DATE '2026-01-01','ENROLLED',18000,NULL)]',-1);
 expect_error('NOT NULL student name',q'[INSERT INTO students VALUES (900003,1,'TEST-NULL',NULL,'test.null@university.example',DATE '2026-01-01','ACTIVE')]',-1400);
 expect_error('Missing program foreign key',q'[INSERT INTO students VALUES (900004,999999,'TEST-FK','Test','test.fk@university.example',DATE '2026-01-01','ACTIVE')]',-2291);
 expect_error('Invalid course credits',q'[UPDATE courses SET credits=0 WHERE course_id=1]',-2290);
 expect_error('Invalid final grade',q'[UPDATE enrollments SET final_grade='Z' WHERE enrollment_id=1]',-2290);
 expect_error('Zero payment amount',q'[UPDATE payments SET amount=0 WHERE payment_id=1]',-2290);
 expect_error('Payment protects enrollment history',q'[DELETE FROM enrollments WHERE enrollment_id=1]',-2292);
END;
/

-- Referential actions are proved using temporary rows and rolled back.
DECLARE
 v_count NUMBER;
BEGIN
 SAVEPOINT actions_test;
 INSERT INTO students VALUES (900005,1,'TEST-CASCADE','Cascade Test','cascade.test@university.example',DATE '2026-01-01','ACTIVE');
 INSERT INTO student_profiles VALUES (900005,DATE '2000-01-01',NULL,'Test Contact','Y');
 DELETE FROM students WHERE student_id=900005;
 SELECT COUNT(*) INTO v_count FROM student_profiles WHERE student_id=900005;
 IF v_count<>0 THEN RAISE_APPLICATION_ERROR(-20002,'CASCADE failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE CASCADE profile');
 INSERT INTO instructors VALUES (900006,1,'Temporary Instructor','temporary.instructor@university.example','ACTIVE');
 INSERT INTO sections VALUES (900006,1,5,900006,'99','ONLINE','OPEN');
 DELETE FROM instructors WHERE instructor_id=900006;
 SELECT COUNT(*) INTO v_count FROM sections WHERE section_id=900006 AND instructor_id IS NULL;
 IF v_count<>1 THEN RAISE_APPLICATION_ERROR(-20003,'SET NULL failed'); END IF;
 DBMS_OUTPUT.PUT_LINE('PASS: ON DELETE SET NULL instructor');
 ROLLBACK TO actions_test;
EXCEPTION WHEN OTHERS THEN ROLLBACK TO actions_test; RAISE;
END;
/
COMMIT;

-- 8. DATA AUDIT AND LIMIT DIAGNOSTICS -------------------------------
-- Expected rows: departments 5, programs 5, students 10, profiles 10,
-- instructors 5, courses 10, terms 5, sections 10, enrollments 12, payments 12.
SELECT 'DEPARTMENTS' AS table_name,COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'PROGRAMS',COUNT(*) FROM programs
UNION ALL SELECT 'STUDENTS',COUNT(*) FROM students
UNION ALL SELECT 'STUDENT_PROFILES',COUNT(*) FROM student_profiles
UNION ALL SELECT 'INSTRUCTORS',COUNT(*) FROM instructors
UNION ALL SELECT 'COURSES',COUNT(*) FROM courses
UNION ALL SELECT 'TERMS',COUNT(*) FROM terms
UNION ALL SELECT 'SECTIONS',COUNT(*) FROM sections
UNION ALL SELECT 'ENROLLMENTS',COUNT(*) FROM enrollments
UNION ALL SELECT 'PAYMENTS',COUNT(*) FROM payments;
-- Zero rows expected: overpayment is detected, not enforceable in a CHECK.
SELECT enrollment_id,balance_due FROM v_enrollment_balance WHERE balance_due<0;
-- Zero rows expected: active student without profile (profile remains optional by design).
SELECT s.student_id FROM students s WHERE s.student_status='ACTIVE'
AND NOT EXISTS (SELECT 1 FROM student_profiles p WHERE p.student_id=s.student_id);

-- 9. SECURITY: OPTIONAL DBA-ENABLED SECTION -------------------------
-- Hosted APEX schemas commonly lack CREATE ROLE. Keep FALSE by default.
DECLARE
 c_enable_security CONSTANT BOOLEAN := FALSE;
BEGIN
 IF c_enable_security THEN
  EXECUTE IMMEDIATE 'CREATE ROLE ur_registrar';
  EXECUTE IMMEDIATE 'CREATE ROLE ur_finance';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON students TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON student_profiles TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT SELECT ON programs TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT SELECT ON courses TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT SELECT ON terms TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON sections TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON enrollments TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_enrollment_details TO ur_registrar';
  EXECUTE IMMEDIATE 'GRANT ur_registrar TO ur_finance';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_enrollment_balance TO ur_finance';
  EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON payments TO ur_finance';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_top5_students_by_tuition TO ur_finance';
  DBMS_OUTPUT.PUT_LINE('Security roles created; DBA must assign them to database users.');
 ELSE
  DBMS_OUTPUT.PUT_LINE('NOT RUN: optional CREATE ROLE / GRANT section; requires DBA approval.');
 END IF;
END;
/
SELECT table_name,constraint_name,constraint_type,status FROM user_constraints
WHERE table_name IN ('DEPARTMENTS','PROGRAMS','STUDENTS','STUDENT_PROFILES','INSTRUCTORS','COURSES','TERMS','SECTIONS','ENROLLMENTS','PAYMENTS')
ORDER BY table_name,constraint_type,constraint_name;
SELECT object_name,status FROM user_objects
WHERE object_name IN ('V_ENROLLMENT_DETAILS','V_ENROLLMENT_BALANCE','V_TOP5_STUDENTS_BY_TUITION');
-- END OF SCRIPT
