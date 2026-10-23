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

## Tech
MySQL 8.4 LTS · VS Code + SQLTools

