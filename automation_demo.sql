USE inventory_mgt;


SELECT customer_id, CONCAT(first_name, ' ', last_name) AS customer, tier
  FROM customers
 ORDER BY customer_id;


CALL refresh_customer_tiers();

SELECT customer_id, CONCAT(first_name, ' ', last_name) AS customer, tier
  FROM customers
 ORDER BY customer_id;


SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer,
       SUM(o.total_amount) AS total_spent, c.tier
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
 WHERE c.customer_id = 2
 GROUP BY c.customer_id, c.first_name, c.last_name, c.tier;

CALL place_order(2, '[{"product_id":5,"quantity":1}]', @order_id);

SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer,
       SUM(o.total_amount) AS total_spent, c.tier
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
 WHERE c.customer_id = 2
 GROUP BY c.customer_id, c.first_name, c.last_name, c.tier;


SELECT product_id, product_name, stock_quantity, reorder_level
  FROM products
 WHERE stock_quantity <= reorder_level
 ORDER BY product_id;


CALL replenish_product(3, 20, 'Supplier delivery - invoice INV-1042');

SELECT log_id, product_id, change_type, quantity_change,
       stock_before, stock_after, note, changed_at
  FROM inventory_logs
 WHERE product_id = 3
 ORDER BY log_id;


CALL replenish_low_stock(@replenished_count);

SELECT @replenished_count AS products_replenished;

SELECT il.log_id, p.product_name, il.quantity_change,
       il.stock_before, il.stock_after, p.reorder_level, il.note
  FROM inventory_logs il
  JOIN products p ON p.product_id = il.product_id
 WHERE il.change_type = 'REPLENISHMENT'
 ORDER BY il.log_id;


SELECT product_id, product_name, stock_quantity, reorder_level
  FROM products
 WHERE stock_quantity <= reorder_level;


SELECT p.product_id, p.product_name, p.stock_quantity,
       SUM(il.quantity_change) AS sum_of_log,
       p.stock_quantity = SUM(il.quantity_change) AS matches
  FROM products p
  JOIN inventory_logs il ON il.product_id = p.product_id
 GROUP BY p.product_id, p.product_name, p.stock_quantity;


SHOW EVENTS;

SHOW VARIABLES LIKE 'event_scheduler';


-- CALL replenish_product(999, 10, NULL);


-- CALL replenish_product(1, 0, NULL);