# Database Management Systems II

## Final Project: Enterprise Database Application Development Using Oracle APEX

**2 students per group \| Total: 100 marks \| Extra Credit: up to +5**

# 1. Project Purpose

Design and implement a complete enterprise database and a working web application. The project has three connected stages: (1) database design in MySQL Workbench, (2) database implementation and SQL programming in Oracle APEX and (3) development of the user-facing application in Oracle APEX.

# 2. Choose a Business Topic

Choose one realistic topic, or propose another Topic for approval:

- E-commerce / Retail

- University Registration

- Healthcare / Hospital

- Hotel / Resort

- Logistics / Fleet Management

- Fitness Club / Membership

# 3. Stage 1 — Database Design (MySQL Workbench)

Create a complete Entity Relationship Diagram (ERD) before implementing the database. Your design must include:

- At least 10 related tables representing a realistic business system.

- At least one 1:1 relationship and multiple 1:N relationships.

- At least one M:N relationship resolved using a junction/associative table.

- Primary keys and foreign keys for all relevant relationships.

- A normalized design in Third Normal Form (3NF).

- Clear table, attribute, relationship, and cardinality naming.

- Business rules that can be enforced through database constraints.

Submit the final ERD as part of the report.

# 4. Stage 2 — Database Implementation (Oracle APEX SQL Workshop)

Implement the approved database design in Oracle APEX SQL Workshop. The database must include:

- Primary Key, Foreign Key, NOT NULL, UNIQUE, and DEFAULT constraints where appropriate.

- At least 3 meaningful CHECK constraints based on business rules.

- Appropriate ON DELETE CASCADE or ON DELETE SET NULL actions, with justification where used.

- At least 5 records in each master/reference table and at least 10 records in each transaction/detail table.

- Realistic and internally consistent sample data.

- Evidence that important constraints have been tested.

- At least 3 views: a multi-table view, an aggregate/summary view, and a restricted or Top-N view.

Views must be meaningful to the selected business domain and not simply duplicate a single table.

# 5. SQL Programming Requirements

Your SQL script must demonstrate all of the following:

- Multi-table queries using JOIN with ON or USING.

- GROUP BY and HAVING with multiple related tables.

- At least 2 subqueries, including at least 1 subquery in the FROM clause.

- A Top-N query using an inline subquery and ROWNUM.

- ROLLUP, CUBE, or GROUPING SETS together with GROUPING().

- INSERT, UPDATE, and DELETE operations, including at least one conditional operation using a subquery.

- COMMIT and ROLLBACK demonstrations.

- GRANT privileges on appropriate tables/views for defined user roles.

Students are expected to construct their own SQL solutions. The report should explain the purpose and result of each major query.

# 6. Stage 3 — Oracle APEX Application Development

The project must include an actual working application created using Oracle APEX App Builder.

## 6.1 Required Application Pages and Functions

- A dashboard or home page that presents the main functions and/or key information of the system.

- Create/Insert functionality that allows users to add new records through the application.

- Update functionality that allows users to edit existing records through the application.

- Delete functionality that allows users to remove appropriate records through the application.

- At least 2 Interactive Reports showing useful business data.

- At least 2 Interactive Grids, with at least 1 demonstrating meaningful data manipulation.

- At least 2 charts based on relevant database data.

- Navigation that allows users to move logically between major functions/pages.

- User-friendly labels, forms, messages, and page organization.

## 6.2 Application Design

The application should reflect the chosen business domain rather than appearing as a collection of unrelated database pages.

- Pages should have clear titles and understandable field labels.

- Forms should use appropriate item types and validation where relevant.

- Reports, grids, and charts should answer meaningful business questions.

- The application should provide appropriate success/error feedback.

- Do not expose unnecessary technical/database details to ordinary users.

# 7. Application Testing

Before submission, test both the database and the APEX application. Demonstrate that:

- A user can create a valid record through the application.

- A user can update an existing record through the application.

- A user can delete an appropriate record through the application.

- Database constraints prevent invalid data where appropriate.

- Interactive Reports and Interactive Grids display current database data.

- Charts display meaningful results from the database.

- Relationships and foreign-key rules behave as intended.

- The application remains functional after database changes.

# 8. Project Report

Submit a concise professional report containing:

- Project title, group members, and selected business domain.

- Business problem and short system description.

- Entity relational Diagram and explanation of major relationships.

- Normalization explanation showing how the design satisfies 3NF.

- Table/constraint summary and sample-data strategy.

- Descriptions of the required SQL queries, views, transactions, and security.

- Screenshots of the APEX application pages, reports, grids, charts, and key CRUD functions.

- Testing results and any limitations.

- Conclusion and division of work between group members.

# 9. Final Submission

Each group must submit all of the following:

**1.** Project Report (PDF)

**2.** Complete SQL script containing table creation, constraints, sample data, views, queries, DML, transactions, and privileges

**3.** Working Oracle APEX application

**4.** Final project demonstration/presentation

# 10. Final Presentation

During the final presentation, each group must explain and demonstrate the database and the APEX application. Both members must understand the project and be able to answer questions about the design, SQL, implementation, application functionality, and testing. Both members must be present during the Final Presentation.

**Important Note:** Students must successfully demonstrate their project and answer questions about their implementation during the final presentation.

Create/Insert, Update, and Delete functionality must be demonstrated successfully through the APEX application during the final presentation.

**The final score will be based on their demonstrated understanding and performance; students who cannot explain or answer questions about their work will not receive marks for those components.**

# Important Requirement

**A submission consisting only of an Entity Relationship Diagram (ERD) and SQL/SQL Workshop work is incomplete. The final project must include a functioning Oracle APEX application with CRUD functionality, Interactive Reports, Interactive Grids, charts, and a dashboard/home page.**

# 11. Minimum Technical Checklist

| **Area** | **Minimum Requirement** |
|----|----|
| Database design | ≥10 related tables; 1:1; multiple 1:N; ≥1 M:N resolved by junction table; 3NF |
| Constraints | PK, FK, NOT NULL, UNIQUE, DEFAULT; ≥3 meaningful CHECK constraints |
| Referential actions | Appropriate ON DELETE CASCADE or SET NULL where needed |
| Sample data | ≥5 records per master/reference table; ≥10 per transaction/detail table |
| Views | ≥3 meaningful views: multi-table, aggregate/summary, restricted or Top-N |
| SQL | JOIN; GROUP BY/HAVING; ≥2 subqueries; ≥1 FROM subquery; Top-N with ROWNUM; ROLLUP/CUBE/GROUPING SETS + GROUPING() |
| DML | INSERT, UPDATE, DELETE; ≥1 conditional operation using a subquery |
| Transactions | COMMIT and ROLLBACK |
| Security | GRANT privileges for defined roles |
| APEX application | Dashboard/home page; Create; Update; Delete; ≥2 Interactive Reports; ≥2 Interactive Grids; ≥2 charts |
| Testing | Database constraints and application CRUD/report/grid/chart functionality tested |
| Submission | Report + SQL script + working APEX application + final demonstration |

# 12. Important SQL and APEX Notes

- The SQL script must be executable in the intended Oracle APEX/Oracle database environment after appropriate ordering of objects.

- Do not use meaningless tables, constraints, views, queries, or charts simply to meet a numerical requirement.

- Sample data must support the required queries, reports, grids, and charts.

- The APEX application must use the implemented database; screenshots alone do not demonstrate a working application.

- Students should test CRUD operations with realistic records before the final demonstration.

- If a technical limitation prevents a requested database feature in the available Oracle APEX environment, document the limitation and provide the closest valid implementation.

# 13. Suggested Project Structure

**Design → Implement → Query → Build → Test → Demonstrate**

- 1\. Select the business domain and identify business processes.

- 2\. Design and normalize the database in MySQL Workbench.

- 3\. Implement tables, relationships, constraints, and sample data in Oracle APEX SQL Workshop.

- 4\. Create views and required SQL queries; test DML, transactions, and privileges.

- 5\. Build the user-facing application in Oracle APEX App Builder.

- 6\. Add forms, CRUD processes, Interactive Reports, Interactive Grids, charts, and dashboard content.

- 7\. Test the complete system and document the results.

- 8\. Prepare the report, SQL script, application, and final demonstration.

# 14. Academic and Project Integrity

All submitted work must be understood by both group members. If external tools, templates, AI assistants, or other resources are used, students remain responsible for the correctness, security, and explanation of the submitted work.

**End of Project Instructions**
