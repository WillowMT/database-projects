# University Registration Database
## Database Management Systems II — Database Programming Report

**Business domain:** university registration and course-tuition installments  
**Target platform:** Oracle Database 19c+; Oracle APEX SQL Workshop  
**Currency:** Thai baht (THB)  
**Scope:** database design and SQL only; no application development.

## 1. Deliverables and execution

- `university_registration.sql` — one ordered Oracle script: schema, seed data, views, queries, DML/transactions, tests, diagnostics and optional security.
- `university_registration.mmd` — editable Mermaid ERD source.
- `university_registration.png` — PNG rendered from the supplied Mermaid source.
- `university_registration_report.md` — this report.

Run the SQL once in a **fresh Oracle schema** with CREATE TABLE and CREATE VIEW privileges. In APEX use **SQL Workshop → SQL Scripts** to upload and run the complete file; inspect statement results and DBMS_OUTPUT. The script intentionally has no DROP statements, reset, SQL*Plus commands, or application code. Oracle DDL implicitly commits, so a failure can leave earlier objects; correct the cause in a clean schema instead of blindly rerunning.

## 2. Design and sample data

The model contains **exactly ten tables**.

| Table | Purpose | Key | Seed rows |
|---|---|---|---:|
| departments | Academic department identity | department_id | 5 |
| programs | Award program offered by a department | program_id | 5 |
| students | Student identity and program | student_id | 10 |
| student_profiles | Optional private/contact extension | student_id (shared PK/FK) | 10 |
| instructors | Teaching staff | instructor_id | 5 |
| courses | Department-owned course catalog | course_id | 10 |
| terms | Academic calendar terms | term_id | 5 |
| sections | A course offering in one term | section_id | 10 |
| enrollments | Student–section M:N junction and booked tuition | enrollment_id | 12 |
| payments | Tuition installments against an enrollment | payment_id | 12 |

The seed has ten sensible fictional students, twelve enrollments, and twelve dated installments. Master/reference groups meet the five-row minimum; all required detail groups—profiles, sections, enrollments, and payments—meet the ten-row minimum. `enrollments.booked_tuition` captures the tuition agreed when the registration was created; `courses.current_tuition` remains a mutable catalog price. Payments are children of enrollment rather than of the student, so every installment has a specific course-registration purpose.

A program determines a student's department through `students.program_id → programs.department_id`; therefore **students does not store a redundant department_id**. A section links exactly one course and term and may temporarily have no instructor. The ERD correctly shows the instructor-to-section parent end as optional and profile as a shared-PK zero-or-one extension.

## 3. Relationships and integrity

- **1:0..1:** `students → student_profiles`. The profile's shared `student_id` primary key/FK permits at most one profile and permits no profile.
- **1:M:** department/program, program/student, department/instructor, department/course, course/section, term/section, student/enrollment, section/enrollment, and enrollment/payment.
- **M:N:** students and sections are resolved by `enrollments`. `UNIQUE(student_id, section_id)` prevents duplicate registration in one section.

Every table has a primary key. Required facts use NOT NULL; business identities use UNIQUE; and defaults apply to award level, statuses, contact consent, section delivery/status, and dates. CHECK constraints validate: program award, status lists, course credits (1–6), positive catalog/booked tuition and payment amounts, valid term date order and midnight-only date values, enrollment dates, and allowed grades. These checks are intentionally explained in the SQL comments and provide more than the three required checks.

`student_profiles.student_id` uses `ON DELETE CASCADE` because a dependent optional contact record has no independent historical meaning. `sections.instructor_id` uses `ON DELETE SET NULL` to preserve the offering if a staff identity is removed. Payment/enrollment and other history-bearing foreign keys are restrictive, so an enrollment with receipts cannot be removed. Both referential actions are tested on temporary data and rolled back.

## 4. 3NF normalization and dependencies

All attributes are atomic (1NF). The only natural association is stored as one enrollment row per student-section pair; no course or payment lists are embedded in a student row.

Key functional dependencies include:

- `department_id → department_code, department_name, office_phone`
- `program_id → department_id, program_code, program_name, award_level`
- `student_id → program_id, student_number, full_name, university_email, admitted_on, student_status`
- `student_id (student_profiles) → birth_date, mobile_phone, emergency_contact, consent_to_contact`
- `instructor_id → department_id, full_name, university_email, employment_status`
- `course_id → department_id, course_code, course_title, credits, current_tuition`
- `term_id → term_code, term_name, starts_on, ends_on, term_status`
- `section_id → course_id, term_id, instructor_id, section_code, delivery_mode, section_status`
- `enrollment_id → student_id, section_id, enrolled_on, enrollment_status, booked_tuition, final_grade`
- `payment_id → enrollment_id, paid_on, amount, payment_method, payment_reference`

Non-key values depend on their table key, not on other non-key attributes. Department facts are not duplicated into students, programs do not copy department names, and sections do not copy course title/credits or term dates. `booked_tuition` is a justified historical snapshot: it records the amount accepted at enrollment and must not be overwritten when `current_tuition` changes. Totals, paid value, and balances are calculated rather than stored, avoiding update anomalies and redundant aggregates.

## 5. Views and queries

| Item | Explanation / expected result |
|---|---|
| `v_enrollment_details` | Multi-table operational view: one row per enrollment with student, program, course, term, section, optional instructor, booked tuition and grade. |
| `v_enrollment_balance` | Preaggregates payments by enrollment before the join; returns booked, paid, and balance without multiplying installments. |
| `v_top5_students_by_tuition` | Deterministic Top-5 aggregate. Its inline query orders first; outer `ROWNUM <= 5` is therefore correct Oracle Top-N syntax. |
| Q1 | JOIN ... ON through V1; ordered enrollment context. |
| Q2 | GROUP BY/HAVING finds students registered in at least two sections; Anan Suri and Maya Chen qualify in the seed. |
| Q3 | Scalar subquery returns registrations above average booked tuition. |
| Q4 | First FROM-clause subquery totals booked tuition per student, filtering totals above THB 30,000. |
| Q5 | Second FROM-clause subquery aggregates booked, paid, and unpaid amounts per section. |
| Q6 | Sorted inline query with outer ROWNUM returns five largest balances. |
| Q7 | `ROLLUP` and `GROUPING()` produce term/status detail, subtotals, and grand total. |

The balance view is deliberately noninflated: `payments` is independently grouped by `enrollment_id`, then joined once to `enrollments`. It never joins multiple raw payment rows alongside another child table. `NVL` treats an enrollment with no payment as paid THB 0. The script's overpayment diagnostic should return zero rows for seed data.

## 6. DML, transactions, security, and tests

The transaction section performs INSERT, UPDATE, and DELETE. It commits a temporary student, updates it, then executes ROLLBACK; the following SELECT should show `Transaction Demo` and default status `ACTIVE`. A correlated `NOT EXISTS` DELETE removes that temporary student only when it has no enrollment. A tuition update using an `IN (SELECT...)` conditional subquery is rolled back to a savepoint so seed catalog prices remain unchanged.

The negative-test PL/SQL helper creates a savepoint for each attempted invalid statement, checks the actual expected SQLCODE, and rolls back. Expected codes are: duplicate PK/UNIQUE `-1`; NOT NULL `-1400`; missing FK `-2291`; CHECK violations `-2290`; restricted deletion of paid enrollment `-2292`. Unexpected success raises `-20001`; unexpected error codes are re-raised.

Security has `c_enable_security CONSTANT BOOLEAN := FALSE`. The default script therefore creates no roles and grants no privileges. On a DBA-approved dedicated database only, changing it to TRUE creates `ur_registrar` and `ur_finance`; registrar manages registration records and finance adds payments/read balances. APEX application usernames are not database users, and no grant to PUBLIC is made.

## 7. Requirements mapping

| Requirement | Evidence |
|---|---|
| Exactly 10 related tables | Section 2 table inventory; 10 CREATE TABLE statements |
| Optional shared-PK 1:1 | student_profiles PK/FK and ERD |
| Student/section M:N | enrollments plus unique pair |
| Tuition snapshot and installments | booked_tuition; payments.enrollment_id |
| PK/FK/UNIQUE/NOT NULL/DEFAULT/CHECK | Section 3 and SQL DDL |
| CASCADE / SET NULL | profile cascade; section instructor set null; rollback-safe test |
| Minimum seed volume | counts in Section 2 and SQL audit |
| Three views | V1 details, V2 balances, V3 Top-5 |
| JOIN, HAVING, subqueries, Top-N, ROLLUP | Q1–Q7 |
| INSERT/UPDATE/DELETE, conditional subquery, COMMIT/ROLLBACK | SQL Section 6 |
| Security roles/GRANT | disabled optional flag section |
| Tests and integrity diagnostics | SQL Sections 7–8 |

## 8. Honest limits and verification status

**Static validation was performed:** the destination contains only the four listed artifacts; SQL was counted for ten CREATE TABLE statements and three CREATE VIEW statements; Mermaid relation/entity and SQL column alignment was manually/static checked; and the PNG was rendered from the `.mmd` through Kroki. The report makes no claim that Oracle runtime output was captured.

**Oracle execution is unexecuted/pending.** No Oracle Database connection was available to run this artifact. Expected row counts and SQLCODE values are documented test expectations, not invented results. Before academic submission, run it in the stated target schema and retain actual SQL Workshop output.

The teaching schema does **not** enforce section capacity, timetable collisions, prerequisites, program/course eligibility, one enrollment per course across sections, enrollment within term dates, payment amounts not exceeding booked tuition, grade/status transitions, refunds, or posted-record immutability. Those cross-row/concurrent rules require transaction-safe procedures, triggers with careful locking, or an application service. The database deliberately preserves payment-linked enrollment history through restrictive FKs, but no audit trail or soft-delete model is supplied.

## 9. Sources and exclusions

Coverage was patterned against the existing local reference artifacts **`hotel_management.sql`** and **`hotel_report.md`** in `/opt/data/database-projects/hotel`, especially their Oracle/APEX execution guidance, snapshot-price rationale, independently aggregated balance view, transaction tests, and honest runtime limitations.

Course documentation cited for requirements coverage:

1. **DB_II_Final_Project_Instructions.docx** — design, implementation, programming, report, environment limitation, and integrity expectations.
2. **Project_Assessment_Rubric.docx** — ERD, normalization, sample-data, SQL/views, transaction/security, testing, and documentation criteria.

Excluded by scope: a working Oracle APEX application, application screenshots/demo, and a MySQL Workbench design artifact. Mermaid source plus its PNG are included as the requested ERD deliverables; they are not represented as a Workbench model.
