
USE inventory_mgt;



-- Alice: a simple multi-product order, no discounts
CALL place_order(1, '[{"product_id":1,"quantity":2},
                      {"product_id":2,"quantity":1},
                      {"product_id":6,"quantity":3}]', @order_id);
SELECT @order_id AS alice_order;

-- Brian: bulk quantities -> 10% off notebooks (25 units), 5% off pens (12 units)
CALL place_order(2, '[{"product_id":6,"quantity":25},
                      {"product_id":7,"quantity":12}]', @order_id);

-- Chloe: higher-value items
CALL place_order(3, '[{"product_id":5,"quantity":2},
                      {"product_id":4,"quantity":1}]', @order_id);

-- David: a big business order (5% off 10 keyboards)
CALL place_order(4, '[{"product_id":5,"quantity":5},
                      {"product_id":2,"quantity":10}]', @order_id);

-- Alice again: a second order
CALL place_order(1, '[{"product_id":10,"quantity":4},
                      {"product_id":11,"quantity":2}]', @order_id);

-- Esther: 10% off 20 yoga mats
CALL place_order(5, '[{"product_id":13,"quantity":20},
                      {"product_id":15,"quantity":5}]', @order_id);

-- -------------------------------------------------------------
-- Check the results
-- -------------------------------------------------------------

SELECT o.order_id, CONCAT(c.first_name, ' ', c.last_name) AS customer,
       o.order_date, o.total_amount
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
 ORDER BY o.order_id;

SELECT od.order_id, p.product_name, od.quantity, od.unit_price,
       od.discount_percent, od.line_total
  FROM order_details od
  JOIN products p ON p.product_id = od.product_id
 ORDER BY od.order_id, od.order_detail_id;

SELECT o.order_id, o.total_amount, SUM(od.line_total) AS sum_of_lines,
       o.total_amount = SUM(od.line_total) AS matches
  FROM orders o
  JOIN order_details od ON od.order_id = o.order_id
 GROUP BY o.order_id, o.total_amount;

SELECT il.order_id, p.product_name, -il.quantity_change AS units_used,
       il.stock_before, il.stock_after
  FROM inventory_logs il
  JOIN products p ON p.product_id = il.product_id
 WHERE il.change_type = 'ORDER'
 ORDER BY il.order_id, il.log_id;

SELECT log_id, changed_at, change_type, quantity_change,
       stock_before, stock_after, order_id, note
  FROM inventory_logs
 WHERE product_id = 5
 ORDER BY log_id;


SELECT p.product_id, p.product_name, p.stock_quantity,
       SUM(il.quantity_change) AS sum_of_log,
       p.stock_quantity = SUM(il.quantity_change) AS matches
  FROM products p
  JOIN inventory_logs il ON il.product_id = p.product_id
 GROUP BY p.product_id, p.product_name, p.stock_quantity;

