# E-commerce Database System
## Database Management Systems II — Database Programming Report

**Business domain:** Online retail orders and fulfilment  
**Platform:** Oracle Database 19c or later; Oracle APEX SQL Workshop  
**Currency:** Thai baht (THB)  
**Student names / contributions:** Unspecified; complete with the actual submitting students and their real work.  
**Scope:** Database design and SQL programming only; no application is included.

## 1. Purpose, files, and execution

This ten-table design records customers and delivery addresses, catalogue products/categories, orders and their historical line prices, carriers/shipments, payments, and product reviews. It deliberately excludes carts, inventory movements, promotions, returns/refunds, supplier purchasing, tax invoices, and an APEX application to stay within the requested database package.

- `ecommerce.sql` — ordered fresh-schema Oracle script: DDL, constraints, seed data, views, queries, DML/transactions, tests, audit, optional roles.
- `ecommerce.mmd` — editable Mermaid ERD.
- `ecommerce.png` — rendered ERD.
- `ecommerce_report.md` — this report.

Run the SQL once in a **fresh** schema from APEX **SQL Workshop → SQL Scripts**. PL/SQL blocks use `/` terminators. It intentionally has no DROP statements and no SQL*Plus directives. Oracle DDL commits implicitly: a failed installation can leave objects, so correct the issue in a separate clean schema rather than rerunning blindly. Inspect statement results, DBMS_OUTPUT, the audit counts, diagnostics, constraints, and view status. In a non-APEX client, enable server output in that client if needed.

## 2. Schema, relationships, and sample data

| Table | Purpose | PK | Seed rows |
|---|---|---|---:|
| customers | Identity, contact, lifecycle | customer_id | 10 |
| addresses | Customer delivery locations | address_id | 10 |
| categories | Product catalogue groups | category_id | 5 |
| products | Current catalogue/inventory facts | product_id | 10 |
| carriers | Delivery service reference data | carrier_id | 5 |
| orders | Order header and delivery charge/discount | order_id | 10 |
| order_items | Historical purchased product/price/quantity | order_id + product_id | 12 |
| shipments | Optional fulfilment record | shipment_id | 10 |
| payments | Payment attempts/receipts | payment_id | 10 |
| reviews | Customer product feedback | review_id | 10 |

Every master/reference table has at least five rows; each transaction/detail table has at least ten. Dates are explicit Oracle DATE literals and identities use fictional example domains. `order_items.unit_price` is the price agreed on an order, distinct from mutable `products.list_price`; line discounts are also historical facts. The sample has two multi-item orders, repeat customer Anan, nine delivered shipments, one shipped and one pending shipment. Reviews include a title, text, rating, author, product, date, and moderation status, making them meaningful feedback rather than anonymous scores.

### Cardinality

- A customer owns zero or more addresses and places zero or more orders; an order requires one customer and one shipping address.
- A category has zero or more products; every product belongs to one category.
- Orders and products are M:N through `order_items`. Oracle can create an order before details, but the seeded orders have one or more lines.
- An order has zero or one shipment: `shipments.order_id` is NOT NULL and UNIQUE. A shipment has zero or one carrier because deleting a carrier sets that FK NULL.
- An order has zero or more payments. Customers and products each have zero or more reviews; a customer may review a particular product once (`UNIQUE(customer_id,product_id)`).

## 3. Normalization and integrity

**1NF:** all attributes are atomic; ordered products are separate `order_items` rows, not lists.  
**2NF:** the composite `order_items` key identifies a particular order-product occurrence; quantity, historical price, and discount describe that whole pairing.  
**3NF:** category facts are separated from products; customer contact data from orders; carrier facts from shipments; and payment/review facts from order lines. Totals are calculated rather than stored.

Every table has a PK. FKs prevent orphan rows; NOT NULL requires identifying facts; UNIQUE protects customer email, SKU, category/carrier names, address labels per customer, shipment/order, tracking number, payment reference, and review uniqueness. Defaults cover statuses, dates, quantities, price/discount values, country and stock. Checks restrict statuses, labels, positive prices/amounts/quantities, nonnegative stock and fees, item discounts, review ratings, and shipment chronology.

`ON DELETE CASCADE` is used only for owned, nonfinancial details: customer addresses and order items. `ON DELETE SET NULL` on shipment carrier preserves a shipment record if carrier reference data is removed. Other FKs intentionally restrict deletion to protect products, order/payment history, and reviews. FK indexes support joins and parent operations; PK/UNIQUE indexes are not duplicated.

**Rules documented but not enforced across rows:** an order address must belong to its customer; ordered quantity must not exceed stock; a reviewer should have bought the reviewed product; captured payments should reconcile to order totals; stock decrement/reservation, status/payment/shipment lifecycle transitions, refunds, and concurrent checkout need controlled procedures/triggers and locking. The final diagnostics check selected seed-data invariants but do not make concurrent writes safe.

## 4. Views and SQL queries

1. **`v_order_details`** is a multi-table operational view, one row per order item, joining customer, product, shipment and carrier information. Shipment/carrier joins are LEFT JOINs for incomplete fulfilment.
2. **`v_order_summary`** computes item total, shipping, order discount, captured payment total and balance by order. Item and payment children are **preaggregated separately** before joining, preventing the fanout that would otherwise multiply totals when an order has several items and payments.
3. **`v_top5_customers`** groups calculated order totals by customer, sorts inside an inline view, then applies `ROWNUM <= 5` outside; it excludes contact data and breaks ties by customer ID.

| Label | Technique | Question |
|---|---|---|
| Q1 | JOIN ... ON | Which products, customers, and fulfilment facts are on each ordered line? |
| Q2 | GROUP BY / HAVING | Which customers placed at least two orders? |
| Q3 | Scalar subquery | Which calculated orders exceed average calculated order value? |
| Q4 | FROM-clause subquery | Which customers spent over THB 1,000? |
| Q5 | ordered inline view + ROWNUM | Which five orders have highest balance due? |
| Q6 | ROLLUP + GROUPING | What is item revenue by category/status with subtotals/grand total? |
| Q7 | correlated NOT EXISTS | Which active products were never purchased? |

## 5. DML, transactions, and security

The script commits a temporary customer, changes its name, then executes ROLLBACK; the following SELECT should show the committed original name and default status. A correlated `NOT EXISTS` conditional DELETE then removes the temporary customer only if it has no order. A category IN-subquery UPDATE temporarily raises active catalogue prices, then rolls back to a savepoint; historical item prices remain unchanged.

Optional roles are guarded by `c_enable_security CONSTANT BOOLEAN := FALSE`. This is intentional: hosted APEX schemas often lack `CREATE ROLE` privileges. With the default flag, no role or grant is attempted; DBMS_OUTPUT says NOT RUN. On an authorized dedicated database, a DBA may set it TRUE and then assign `ec_sales`/`ec_manager` to actual database users. There is no PUBLIC grant. APEX login authorization is separate from database roles.

## 6. Tests and verification status

The script embeds rollback-safe tests for duplicate PK/email, NOT NULL, FK, positive price/quantity, shipment chronology, one shipment per order, rating range, and protected order history. Each negative test establishes a savepoint, checks its expected Oracle SQLCODE (`-1`, `-1400`, `-2291`, `-2290`, or `-2292`), rolls back, re-raises unexpected errors, and raises an application error if an invalid statement succeeds. A second test validates SET NULL carrier and CASCADE order-item actions then rolls back.

**No Oracle connection was available during preparation.** Oracle execution results are therefore not claimed. Expected outcomes and audit counts are test expectations, not invented runtime evidence. The artifact was statically checked for ten table definitions, seed-row targets, required clauses and ERD rendering; static checks cannot prove Oracle compilation or all runtime semantics. Students must run it in their target Oracle/APEX schema and retain actual output/screenshots if their assignment requires them.

The final row audit should show: customers 10, addresses 10, categories 5, products 10, orders 10, order_items 12, shipments 10, carriers 5, payments 10, reviews 10. Diagnostics should return zero rows for mismatched order address/customer, ordered quantity above current stock, nonpositive captured payment, and blank review text.

## 7. Requirements mapping

| Requirement | Implementation |
|---|---|
| Exactly 10 related tables | Ten named tables in Section 1 |
| Optional 1:1 | UNIQUE NOT NULL `shipments.order_id` FK |
| M:N | `orders`/`products` through `order_items` |
| 3NF / historical amounts | normalized entity facts; historical line price/discount |
| PK, FK, UNIQUE, NOT NULL, DEFAULT, checks | DDL constraints and defaults |
| Appropriate CASCADE / SET NULL | owned details cascade; carrier SET NULL |
| Minimum sample rows | 5+ masters and 10+ transactions/details |
| Three views | detail, fanout-safe summary, Top-5 |
| JOIN, HAVING, 2+ subqueries, Top-N | Q1–Q5 and views |
| ROLLUP + GROUPING | Q6 |
| INSERT/UPDATE/DELETE, subquery, COMMIT/ROLLBACK | transaction demonstration |
| Constraint tests | expected-code savepoint blocks |
| Roles/GRANT | optional FALSE hosted-APEX-safe block |
| ERD | Mermaid source and PNG |
| Application/screenshots | expressly excluded from this package |

## 8. Source assignment / rubric

This package follows the supplied database-project instructions and assessment rubric as the assignment sources, using the hotel package only as a style and coverage reference. It does not claim access to an Oracle runtime or completion of requirements outside the requested database deliverables. Before submission, replace the unspecified student information with truthful names/contributions, run the script, and disclose tool assistance as required by course policy.
