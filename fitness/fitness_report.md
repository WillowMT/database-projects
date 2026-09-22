# FITNESS CLUB
## Database Management Systems II — Database Programming Report

**Domain:** Fitness club | **Target platform:** Oracle Database 19c+ / Oracle APEX SQL Workshop | **Currency:** THB  
**Scope:** the database-programming package only. APEX application screens and MySQL Workbench artifacts are excluded.

## 1. Purpose, package, and safe execution
This normalized club database manages member identity, optional emergency-contact profiles, plans, purchased memberships, trainers, studios, class catalog/session scheduling, the member/session booking junction, and membership installment payments. `fitness.sql` is ordered for a **fresh schema** and intentionally contains no destructive reset statements or SQL*Plus commands. Oracle DDL implicitly commits: resolve an installation error in a clean schema instead of rerunning blindly over partial objects. In APEX, use SQL Workshop → SQL Scripts and review statement and DBMS_OUTPUT results.

Deliverables are exactly `fitness.sql`, `fitness.mmd`, `fitness.png`, and this `fitness_report.md`. The Mermaid source is editable; the PNG is its rendered ERD. The authoring environment did **not** have an Oracle connection, so this report makes no claim of Oracle runtime execution.

## 2. Ten-table 3NF design and seed counts
| Table | Purpose | PK | Expected rows |
|---|---|---|---:|
| members | identity and membership status | member_id | 10 |
| member_profiles | optional emergency contact; shared PK 1:1 | member_id | 10 |
| membership_plans | current plan catalog | plan_id | 5 |
| memberships | purchased plan term and agreed price | membership_id | 10 |
| trainers | instructor reference data | trainer_id | 5 |
| studios | physical class spaces | studio_id | 5 |
| class_types | current class catalog | class_type_id | 5 |
| class_sessions | scheduled class occurrence | session_id | 10 |
| class_bookings | M:N resolution between members and sessions | booking_id | 10 |
| payments | installment receipts against memberships | payment_id | 10 |

All named reference tables have at least five rows; each requested detail table, including profiles, has at least ten. Dates and payment values are deterministic Oracle literals. Memberships have end dates later than starts, and the supplied payments do not exceed each membership's `booked_price` (the balance view/audit exposes a negative result if this condition is violated).

### Relationships and normalization
`members → member_profiles` is optional 1:0..1 because the profile PK is also a FK. Members can buy many memberships; a plan can be selected many times; a membership has many installments. Members and sessions are M:N through `class_bookings`, protected by a UNIQUE `(session_id, member_id)`. A trainer is optional on a session specifically so deleting a trainer can preserve a scheduled session with `trainer_id` set NULL.

The model is in 3NF: plan facts depend on `plan_id`, class catalog facts on `class_type_id`, studio facts on `studio_id`, and person facts on their person keys. `memberships.booked_price` is intentionally a **historical contract fact**, separate from mutable `membership_plans.list_price`. Payment totals and balances are computed, not stored, avoiding redundant update anomalies. The profile holds emergency-contact data only; it does not represent a medical screening system or claim clinical/security controls.

## 3. Constraints, integrity boundaries, and deletion policy
Every table has a PK; required facts use NOT NULL; business identities use UNIQUE; defaults include status, dates, preferred contact, class fee, and booking state. CHECK constraints enforce controlled statuses/methods, price/amount positivity, installment numbers, plan duration, class duration, studio capacity, birth-date range, and chronological membership/session dates. The static birth-date range avoids an invalid Oracle CHECK referencing `SYSDATE`.

`member_profiles` and `class_bookings` use CASCADE because they are dependent records with no independent meaning; deleting a trainer uses SET NULL so the session remains. Other FKs are restrictive, notably payments → memberships, to protect financial history. Embedded tests verify both actions and expected Oracle errors, rolling temporary changes back.

**Not fully database-enforced:** capacity bookings cannot be compared to `studios.capacity` safely with a row CHECK; an active membership at booking time; instructor/studio time conflicts; and cumulative overpayment require transaction-safe procedures/triggers plus appropriate locking. The script provides an overpayment diagnostic, but does not falsely claim those cross-row/concurrent rules are secured by simple constraints.

## 4. Views and required query evidence
| Object/query | Purpose and expected behavior |
|---|---|
| `v_membership_balance` | Multi-table membership/plan/member view with independently preaggregated payments; one row per membership, no payment fanout. |
| `v_class_session_summary` | Multi-table session operational summary; one row/session with booking and attendance counts. |
| `v_top5_members_by_paid` | Aggregates paid installments by member; sorted inline query with outer `ROWNUM <= 5`. |
| Q1 JOIN | Shows booking roster, member, type, studio, start, and status. |
| Q2 GROUP BY/HAVING | Returns members with at least two bookings. |
| Q3 scalar subquery | Returns memberships above the average balance. |
| Q4 FROM subquery | Returns trainers whose completed sessions have bookings. |
| Q5 Top-N | Five greatest outstanding balances, sorted before ROWNUM. |
| Q6 ROLLUP/GROUPING | Paid revenue by plan/status with unambiguous subtotal/grand-total labels. |

The Top-N view and Q5 deliberately sort inside an inline view before applying `ROWNUM`. Q3 and Q4 satisfy two different subquery forms. Views avoid fanout: payment sums are grouped by membership prior to joining dimensions; session bookings are the only detail joined to a one-session aggregate.

## 5. DML, transactions, tests, and expectations
The SQL demonstrates INSERT, UPDATE, a conditional DELETE containing `NOT EXISTS`, COMMIT, ROLLBACK, and SAVEPOINT/ROLLBACK TO. A temporary member is committed, changed and rolled back, then conditionally deleted and committed. A plan-price update is rolled back, preserving seed catalog prices and never altering historical booked prices.

| Test | Expected when executed in Oracle | Rollback-safe |
|---|---|---|
| duplicate PK / email / booking | `SQLCODE -1` | yes |
| missing member name | `SQLCODE -1400` | yes |
| invalid birth, membership date | `SQLCODE -2290` | yes |
| nonexistent payment membership | `SQLCODE -2291` | yes |
| delete paid membership | `SQLCODE -2292` | yes |
| delete temporary trainer | session remains; trainer FK is NULL | yes |
| delete temporary session | dependent bookings are removed | yes |
| row-count audit | 10 rows for each of 10 tables | read-only |
| negative membership balance audit | zero rows | read-only |

These are expected results, not fabricated execution output. Test code raises an application error if an attempted invalid operation succeeds or returns an unexpected error code.

## 6. Security and limitations
The optional roles/GRANT PL/SQL section has `c_enable_security := FALSE` because hosted APEX schemas commonly cannot create database roles. It is intentionally not executed by default and is not evidence that roles were applied. If DBA-approved on a dedicated Oracle instance, it proposes a reception role with member/session-summary access and a manager role that inherits it and can read membership balances. No grant to PUBLIC is included. APEX authorization and database accounts remain separate.

## 7. Assignment/rubric coverage and source reference
This package is patterned after the coverage level and honest reporting style of `/opt/data/database-projects/hotel/hotel_management.sql` and `hotel_report.md`: fresh-schema Oracle script, exactly ten related tables, historical financial fact, row counts, 3NF explanation, aggregate-safe views, required SQL patterns, rollback-safe negative tests, optional hosted-APEX security, and explicit enforcement limits.

| Assignment/rubric criterion | Fitness implementation |
|---|---|
| ERD, entities, cardinality | `fitness.mmd` and rendered `fitness.png`; all SQL columns/optionality match |
| normalization | Section 2, especially plan price vs booked price |
| DDL integrity | PK/FK/UNIQUE/NOT NULL/default/CHECK and deletion behavior |
| sample testing | ten rows/table, audit and diagnostics |
| advanced SQL | JOIN, HAVING, scalar/FROM subqueries, Top-N, ROLLUP/GROUPING |
| views | three purposeful views with stated grain |
| DML/transactions/security | commits, rollbacks, conditional DML, tests, FALSE hosted-APEX flag |
| documentation | limitations, expected results, and scope disclosed |

**Source assignment/rubric names:** `DB_II_Final_Project_Instructions.docx` and `Project_Assessment_Rubric.docx` are the assignment/rubric names used by the referenced hotel coverage. Confirm locally with the course-provided versions before final submission; no claims are made here about application screenshots or Oracle execution.
