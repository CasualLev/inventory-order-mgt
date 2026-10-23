# Inventory and Order Management System

A MySQL database for managing products, customers, orders and inventory
for an e-commerce company, with automated stock tracking and reporting.

## How to run
Run the scripts in order against MySQL 8.x:

1. `schema.sql` – tables, relationships and constraints

2. `sample_data.sql` – sample products, customers and opening stock

3. `order_processing.sql` – bulk discount function, stock/log/total trigger,
   and the `place_order` procedure (run in Workbench: uses DELIMITER)
4. `order_demo.sql` – sample orders and verification queries

5. `reports.sql` – tier function, order/customer summaries, low-stock,
   spending tiers, bulk discount and sales reports

6. `replenishment_automation.sql` – replenishment procedures, automatic tier
   trigger and daily restock event (run in Workbench: uses DELIMITER)
7. `07_automation_demo.sql` – demonstrates tiers updating and stock replenishment

8. `views.sql` – order summary, low stock, customer spending and inventory history views
9. `load_test_data.sql` – optional: 3,000 customers and 10,000 orders for performance testing
10. `10_performance.sql` – indexes with before/after EXPLAIN comparisons
## Tech
MySQL 8.4 LTS · VS Code + SQLTools

