# Logistics / Fleet Management System
## Database Management Systems II — Database Programming Report

**Business domain:** Depot-to-depot freight, dispatch and fleet maintenance  
**Platform:** Oracle Database 19c+ / Oracle APEX SQL Workshop  
**Currency:** Thai baht (THB); sample identities are fictional.  
**Scope:** database and SQL programming only; no application development.

## 1. Purpose, source and execution

This package models customers booking depot-to-depot freight, a dispatch trip that may carry several shipments, shipment event history, optional proof of delivery, and vehicle maintenance. It follows the supplied **DB_II_Final_Project_Instructions** and **Project_Assessment_Rubric** coverage pattern, using the hotel SQL/report in the supplied workspace as a coverage reference. It intentionally excludes an APEX application, screenshots, and MySQL Workbench artifacts.

`logistics.sql` is ordered for one run in a **fresh** schema. It has no destructive DROP statements and is not an idempotent rerun script; Oracle DDL commits implicitly. Upload it through APEX **SQL Workshop → SQL Scripts** and run the whole script. With SQLcl/SQL*Plus, enable `SET SERVEROUTPUT ON` to see test messages. The role flag remains `FALSE` unless a DBA approves role creation.

## 2. Delivered schema and data

| Table | Role | Key | Seed rows |
|---|---|---|---:|
| customers | freight customer identity | customer_id | 5 |
| depots | named operational geography | depot_id | 5 |
| drivers | licensed fleet staff | driver_id | 5 |
| vehicles | fleet inventory/capacity/current depot | vehicle_id | 5 |
| shipments | booked transport contract | shipment_id | 12 |
| shipment_tracking | 1:N event history | tracking_id | 12 |
| delivery_receipts | optional 1:1 proof of delivery | shipment_id | 10 |
| trips | dispatch movement | trip_id | 10 |
| trip_shipments | trip/shipment M:N leg allocation | trip_id + shipment_id | 14 |
| maintenance_records | vehicle service history | maintenance_id | 10 |

The master/reference tables each have at least five rows. Transaction/detail tables meet the requested minima: 12 shipments, 12 tracking events, 10 receipts, 10 trips, 14 junction rows, and 10 maintenance rows. Dates are plausible January 2026 operations with late-2025/January maintenance; weights fit the demonstrated vehicle capacities. `SHP-2026-009` and `SHP-2026-011` show a multi-leg shipment allocation.

## 3. Relationships and 3NF

`shipments.origin_depot_id` and `shipments.destination_depot_id` are distinct non-null FKs to `depots`, with a CHECK preventing the same depot in both roles. `shipment_tracking` is a shipment’s 1:N history. `delivery_receipts.shipment_id` is both PK and FK, so a shipment has zero or one receipt. `trips` and `shipments` are M:N through `trip_shipments`; the composite key prevents a shipment being repeated on the same trip and `(trip_id, leg_sequence)` is unique. The Mermaid source and PNG contain every column and FK/cardinality label.

The model is in 3NF: `customer_id → customer_name, contact_email, contact_phone, customer_status`; `depot_id → depot_code, depot_name, province, latitude, longitude, depot_status`; `vehicle_id → registration_no, vehicle_type, capacity_kg, vehicle_status, current_depot_id`; and `shipment_id → customer_id, origin_depot_id, destination_depot_id, booked_on, promised_date, weight_kg, freight_charge, shipment_status`. Tracking and maintenance facts depend on their own identifiers. In the associative table, `loaded_kg` and `leg_sequence` describe the trip–shipment association. Customer/depot/vehicle descriptions are not copied into transactions.

A shipment’s `freight_charge` belongs only to `shipments`; it is not copied per trip leg. This avoids double-summing commercial revenue when a shipment has multiple legs. `v_trip_load_summary` aggregates only `loaded_kg`, while customer freight reporting aggregates shipment charge exactly once.

## 4. Constraints and deletion rules

All tables have PKs; required operational relationships and facts are `NOT NULL`. Unique controls include customer email, depot code, driver licence/phone, vehicle registration, shipment/trip numbers, proof reference, tracking event tuple and trip leg sequence. Defaults cover statuses and `booked_on`. CHECK constraints validate geography bounds, controlled statuses/types, positive capacity/weight/load/charge, different origin/destination and start/end depots, shipment/trip chronology, and maintenance values.

`ON DELETE CASCADE` on tracking and receipt FKs removes dependent operational detail only when a shipment is removed; `trip_shipments` cascades with its trip. `ON DELETE SET NULL` preserves vehicles if a temporary depot is removed, preserves tracking history if an event depot is removed, and preserves trips if a driver is removed. Restrictive FKs protect parent references where automatic deletion would be inappropriate. The embedded tests prove one SET NULL and shipment CASCADE case, then roll back.

**Cross-row boundary:** declarative checks cannot ensure no overlapping vehicle/driver schedules, sum of all trip loads ≤ vehicle capacity, a multi-leg shipment’s leg order/location continuity, event sequence/status chronology, event location matching a leg, or that an assigned trip’s endpoints match a shipment’s individual origin/destination (a leg may be intermediate). The script supplies zero-row diagnostics for capacity, vehicle overlap and obvious full-route mismatch. Real dispatch requires transaction-safe procedures/triggers, locking and an explicit route/leg model; it does **not** invent optimized routing.

## 5. Views and SQL coverage

1. **`v_shipment_operations`** is a multi-table operational projection of shipment, customer, both depot roles and optional receipt.
2. **`v_trip_load_summary`** joins trip, vehicle, optional driver and depots, then joins a separately preaggregated trip-load subquery. It reports load, capacity and percentage without pricing duplication.
3. **`v_top5_customers`** groups noncancelled shipment charges, sorts inside an inline view and applies `ROWNUM <= 5` outside it; customer ID resolves ties.

The required-query section includes: a JOIN-based operational report; GROUP BY/HAVING for repeat shippers; a scalar subquery for charges above average; a FROM-clause aggregate subquery for customers over THB 4,000; a sorted inline Top-N query; and `ROLLUP` with `GROUPING()` for freight by origin province/status. Expected results are result sets based on the named question, not claimed runtime output: Q1 has one row per shipment; Q2 returns customers with at least two shipments; Q3 returns above-average charges; Q4 returns qualifying cumulative spenders; Q5 has at most five ordered rows; and Q6 contains detail/subtotal/grand-total labels.

## 6. DML, security and tests

The transaction section inserts/commits a temporary customer, updates then rolls back its name, conditionally deletes it with a correlated `NOT EXISTS`, and performs an `IN (subquery)` vehicle update under a savepoint then rolls it back. Thus no demonstration data persists.

The optional security PL/SQL block has `c_enable_security := FALSE` for hosted APEX. If a DBA changes it to TRUE, `lf_dispatcher` receives customer/shipment/tracking operation and read-only fleet/depot/view access; `lf_manager` inherits it and can manage trips, junction rows and maintenance. No privilege is granted to PUBLIC. These are illustrative database roles, separate from APEX end-user authorization.

Rollback-safe self-checks expect Oracle SQLCODE **-1** for duplicate PK/unique violations, **-1400** for missing mandatory customer name, **-2291** for missing depot FK, **-2290** for CHECK failures, and **-2292** when deleting a shipment protected by its restrictive trip allocation. A referential-action block expects a vehicle to survive a deleted temporary depot with a NULL current depot, and tracking/receipt rows to disappear after temporary-shipment deletion; all test data is rolled back. The audit should return counts `5,5,5,5,12,12,10,10,14,10`; three operational diagnostics should return zero rows for the supplied seed.

## 7. Verification status and rubric mapping

Static preparation checks counted ten `CREATE TABLE` statements, seed-row assumptions, the three views and the four required files; Mermaid is rendered to the supplied PNG. **No Oracle runtime was executed.** Expected query/test outcomes above are not fabricated execution results. Run the complete script in the target Oracle environment, inspect DBMS_OUTPUT/audits, and retain actual results before submitting.

| Assignment/rubric criterion | Package evidence |
|---|---|
| Ten related tables; 1:1, 1:N, M:N | schema section and ERD |
| 3NF; PK/FK/NOT NULL/DEFAULT/UNIQUE/CHECK | Sections 3–4 / table DDL |
| Minimum sample records | Section 2 / audit query |
| Three views and advanced SQL | Section 5 / SQL sections 3–4 |
| INSERT, UPDATE, DELETE, transaction control | SQL section 5 |
| Roles/grants and integrity testing | SQL sections 6 and 8 |
| ERD | `logistics.mmd`, `logistics.png` |
| App/screenshots/Workbench | intentionally excluded from this requested package |

## 8. Source documents

1. **DB_II_Final_Project_Instructions.docx** — design, SQL programming, report, environment and integrity criteria.
2. **Project_Assessment_Rubric.docx** — ERD, normalization, implementation, sample testing, views, transactions/security and documentation criteria.
3. Supplied hotel package (`hotel_management.sql`, `hotel_report.md`) — workspace coverage reference only, not a domain-data source.
