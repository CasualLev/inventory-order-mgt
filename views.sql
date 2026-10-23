USE inventory_mgt;


CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.order_date,
    o.total_amount,
    COUNT(od.order_detail_id)              AS products_in_order,
    SUM(od.quantity)                       AS total_units
FROM orders o
JOIN customers c      ON c.customer_id = o.customer_id
JOIN order_details od ON od.order_id   = o.order_id
GROUP BY o.order_id, c.customer_id, c.first_name, c.last_name, o.order_date, o.total_amount;


CREATE OR REPLACE VIEW vw_low_stock AS
SELECT
    product_id,
    product_name,
    category,
    stock_quantity,
    reorder_level,
    reorder_level - stock_quantity     AS units_below_reorder,
    reorder_level * 2 - stock_quantity AS suggested_restock_qty,
    CASE
        WHEN stock_quantity = 0 THEN 'OUT OF STOCK'
        WHEN stock_quantity < reorder_level THEN 'LOW'
        ELSE 'AT REORDER LEVEL'
    END AS stock_status
FROM products
WHERE stock_quantity <= reorder_level;


CREATE OR REPLACE VIEW vw_customer_spending AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COUNT(o.order_id)                      AS number_of_orders,
    COALESCE(SUM(o.total_amount), 0)       AS total_spent,
    c.tier
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.tier;


CREATE OR REPLACE VIEW vw_inventory_history AS
SELECT
    il.log_id,
    il.changed_at,
    p.product_id,
    p.product_name,
    il.change_type,
    il.quantity_change,
    il.stock_before,
    il.stock_after,
    il.order_id,
    il.note
FROM inventory_logs il
JOIN products p ON p.product_id = il.product_id;


SELECT * FROM vw_order_summary ORDER BY order_date DESC, order_id DESC;


SELECT customer_name, order_id, order_date, total_amount, products_in_order, total_units
  FROM vw_order_summary
 WHERE customer_id = 1;


SELECT * FROM vw_low_stock ORDER BY units_below_reorder DESC;


SELECT * FROM vw_customer_spending ORDER BY total_spent DESC;


SELECT tier, COUNT(*) AS customers, SUM(total_spent) AS revenue
  FROM vw_customer_spending
 GROUP BY tier;


SELECT * FROM vw_inventory_history WHERE product_id = 5 ORDER BY log_id;