USE inventory_mgt;


DROP FUNCTION IF EXISTS fn_customer_tier;

CREATE FUNCTION fn_customer_tier(p_total_spent DECIMAL(12,2))
RETURNS VARCHAR(10)
DETERMINISTIC
NO SQL
RETURN CASE
    WHEN p_total_spent >= 2000 THEN 'Gold'
    WHEN p_total_spent >= 500  THEN 'Silver'
    ELSE 'Bronze'
END;


SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    o.order_id,
    o.order_date,
    COUNT(od.order_detail_id)              AS products_in_order,
    SUM(od.quantity)                       AS total_units,
    o.total_amount
FROM orders o
JOIN customers c      ON c.customer_id = o.customer_id
JOIN order_details od ON od.order_id   = o.order_id
GROUP BY o.order_id, c.first_name, c.last_name, o.order_date, o.total_amount
ORDER BY customer, o.order_date;


SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    COUNT(o.order_id)                      AS number_of_orders,
    COALESCE(SUM(o.total_amount), 0)       AS total_spent,
    ROUND(COALESCE(AVG(o.total_amount), 0), 2) AS avg_order_value,
    MIN(o.order_date)                      AS first_order,
    MAX(o.order_date)                      AS last_order
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;


SELECT
    product_id,
    product_name,
    category,
    stock_quantity,
    reorder_level,
    reorder_level - stock_quantity AS units_below_reorder,
    CASE
        WHEN stock_quantity = 0 THEN 'OUT OF STOCK'
        WHEN stock_quantity < reorder_level THEN 'LOW'
        ELSE 'AT REORDER LEVEL'
    END AS stock_status
FROM products
WHERE stock_quantity <= reorder_level
ORDER BY stock_quantity / NULLIF(reorder_level, 0), product_name;


WITH customer_spend AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer,
        COALESCE(SUM(o.total_amount), 0)       AS total_spent
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    RANK() OVER (ORDER BY total_spent DESC) AS spend_rank,
    customer_id,
    customer,
    total_spent,
    fn_customer_tier(total_spent)           AS tier
FROM customer_spend
ORDER BY spend_rank, customer;


WITH customer_spend AS (
    SELECT
        c.customer_id,
        COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id
)
SELECT
    fn_customer_tier(total_spent)  AS tier,
    COUNT(*)                       AS customers,
    SUM(total_spent)               AS tier_revenue,
    ROUND(AVG(total_spent), 2)     AS avg_spent_per_customer
FROM customer_spend
GROUP BY tier
ORDER BY FIELD(tier, 'Gold', 'Silver', 'Bronze');


SELECT
    q.quantity,
    fn_bulk_discount(q.quantity) AS discount_percent
FROM (SELECT 1 AS quantity UNION ALL SELECT 9 UNION ALL SELECT 10
      UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 49
      UNION ALL SELECT 50 UNION ALL SELECT 100) AS q;


SELECT
    od.order_id,
    CONCAT(c.first_name, ' ', c.last_name)              AS customer,
    p.product_name,
    od.quantity,
    od.unit_price,
    od.discount_percent,
    od.quantity * od.unit_price                         AS full_price,
    od.line_total                                       AS price_paid,
    od.quantity * od.unit_price - od.line_total         AS savings
FROM order_details od
JOIN orders o    ON o.order_id    = od.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p  ON p.product_id  = od.product_id
WHERE od.discount_percent > 0
ORDER BY savings DESC;


SELECT
    CONCAT(c.first_name, ' ', c.last_name)               AS customer,
    SUM(od.quantity * od.unit_price - od.line_total)     AS total_savings
FROM order_details od
JOIN orders o    ON o.order_id    = od.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING total_savings > 0
ORDER BY total_savings DESC;


SELECT
    p.category,
    p.product_name,
    COALESCE(SUM(od.quantity), 0)   AS units_sold,
    COALESCE(SUM(od.line_total), 0) AS revenue
FROM products p
LEFT JOIN order_details od ON od.product_id = p.product_id
GROUP BY p.product_id, p.category, p.product_name
ORDER BY revenue DESC;


SELECT
    p.category,
    COALESCE(SUM(od.quantity), 0)   AS units_sold,
    COALESCE(SUM(od.line_total), 0) AS revenue
FROM products p
LEFT JOIN order_details od ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;