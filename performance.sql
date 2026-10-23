USE inventory_mgt;


SHOW INDEX FROM products;
SHOW INDEX FROM customers;
SHOW INDEX FROM orders;
SHOW INDEX FROM order_details;
SHOW INDEX FROM inventory_logs;


EXPLAIN
SELECT order_id, order_date, total_amount
  FROM orders
 WHERE customer_id = 15
 ORDER BY order_date DESC;


EXPLAIN
SELECT order_id, customer_id, total_amount
  FROM orders
 WHERE order_date >= '2026-10-01' AND order_date < '2026-10-08';


EXPLAIN
SELECT log_id, changed_at, change_type, quantity_change, stock_after
  FROM inventory_logs
 WHERE product_id = 5
 ORDER BY changed_at DESC
 LIMIT 20;


EXPLAIN
SELECT customer_id, first_name, last_name, email
  FROM customers
 WHERE last_name = 'Customer150';


CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date);

CREATE INDEX idx_orders_date ON orders (order_date);

CREATE INDEX idx_logs_product_time ON inventory_logs (product_id, changed_at);

CREATE INDEX idx_customers_name ON customers (last_name, first_name);


ANALYZE TABLE products, customers, orders, order_details, inventory_logs;


EXPLAIN
SELECT order_id, order_date, total_amount
  FROM orders
 WHERE customer_id = 15
 ORDER BY order_date DESC;


EXPLAIN
SELECT order_id, customer_id, total_amount
  FROM orders
 WHERE order_date >= '2026-10-01' AND order_date < '2026-10-08';


EXPLAIN
SELECT log_id, changed_at, change_type, quantity_change, stock_after
  FROM inventory_logs
 WHERE product_id = 5
 ORDER BY changed_at DESC
 LIMIT 20;


EXPLAIN
SELECT customer_id, first_name, last_name, email
  FROM customers
 WHERE last_name = 'Customer150';


EXPLAIN
SELECT order_id, total_amount
  FROM orders
 WHERE YEAR(order_date) = 2025 AND MONTH(order_date) = 6;


EXPLAIN
SELECT order_id, total_amount
  FROM orders
 WHERE order_date >= '2025-06-01' AND order_date < '2025-07-01';


EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
  FROM orders
 WHERE customer_id = 15
 ORDER BY order_date DESC;