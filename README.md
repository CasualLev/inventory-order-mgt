# Inventory and Order Management System

A MySQL database for an e-commerce company that manages products, customers, orders and inventory. Placing an order automatically deducts stock, applies bulk discounts, calculates totals, logs every stock change and updates customer tiers. Low-stock products are replenished automatically.

## Tech Stack

MySQL 8.4 LTS · MySQL Workbench · VS Code + SQLTools

## How to Run

Run the scripts in order. Files marked ⚙ use `DELIMITER`, so run them in MySQL Workbench or the `mysql` command line.

| File | Purpose |
|---|---|
| `schema.sql` | Tables, relationships and constraints |
| `sample_data.sql` | Sample products, customers and opening stock |
| `order_processing.sql` ⚙ | Discount function, stock trigger, `place_order` procedure |
| `order_demo.sql` | Sample orders and verification queries |
| `reports.sql` | Tier function and business reports |
| `replenishment_automation.sql` ⚙ | Replenishment, automatic tiers, daily restock event |
| `automation_demo.sql` | Tier and replenishment demo |
| `views.sql` | Order summary, low stock, spending and inventory views |
| `load_test_data.sql` ⚙ | *Optional:* 3,000 customers and 10,000 orders |
| `performance.sql` | Indexes with before/after `EXPLAIN` |

Re-running `01` to `08` resets the database. Run `10` once per reset.

## Database Design

/er-diagram.png

Foreign keys prevent deleting customers with orders or products with sales history. `CHECK` constraints prevent negative stock, invalid quantities and invalid discounts.

## Business Rules

| Rule | Policy |
|---|---|
| Customer tiers | Bronze < 500 · Silver 500–1,999.99 · Gold ≥ 2,000 (total spent) |
| Bulk discounts | 10–19 units: 5% · 20–49: 10% · 50+: 15% (per product line) |
| Low stock | `stock_quantity <= reorder_level` |
| Replenishment | Restock to 2× reorder level, automatically every day at 06:00 |

## Usage

```sql
CALL place_order(1, '[{"product_id":1,"quantity":2},{"product_id":6,"quantity":25}]', @order_id);
CALL replenish_product(3, 20, 'Supplier delivery');
CALL replenish_low_stock(@count);
SELECT * FROM vw_order_summary;
SELECT * FROM vw_low_stock;
```

## Deliverables

| Deliverable | File(s) |
|---|---|
| Database schema | `01` |
| Order placement and stock updates | `03`, `04` |
| Inventory tracking | `03`, `04`, `08` |
| Customer categorization | `05`, `06` |
| Views | `08` |
| Replenishment system | `06`, `07` |
| Report summaries | `05`, `08` |
| Performance optimization | `09`, `10` |

## Key Design Decisions

- Orders store the price at purchase time, so past orders stay correct when prices change.
- Stock, logging and totals are handled by triggers, so they can't be bypassed.
- Each order runs as one transaction: if any item fails, the whole order is rolled back.
- Row locking (`FOR UPDATE`) prevents overselling when orders arrive at the same time.

## Author

