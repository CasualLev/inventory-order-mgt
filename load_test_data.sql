USE inventory_mgt;

DROP PROCEDURE IF EXISTS generate_load_test_data;


DELIMITER $$


CREATE PROCEDURE generate_load_test_data(IN p_customers INT, IN p_orders INT)
BEGIN
    DECLARE i                    INT DEFAULT 0;
    DECLARE v_customer           INT;
    DECLARE v_product_a          INT;
    DECLARE v_product_b          INT;
    DECLARE v_order_id           INT;
    DECLARE v_first_new_customer INT;

    SELECT COALESCE(MAX(customer_id), 0) + 1 INTO v_first_new_customer FROM customers;

    SET SESSION cte_max_recursion_depth = GREATEST(p_customers + 1, 1000);

    INSERT INTO customers (first_name, last_name, email, phone)
    WITH RECURSIVE seq (n) AS (
        SELECT 1
        UNION ALL
        SELECT n + 1 FROM seq WHERE n < p_customers
    )
    SELECT CONCAT('Test', n),
           CONCAT('Customer', n),
           CONCAT('loadtest', n, '_', UNIX_TIMESTAMP(), '@example.com'),
           NULL
      FROM seq;

    WHILE i < 15 DO
        SET i = i + 1;
        CALL replenish_product(i, 100000, 'Load test stock');
    END WHILE;

    SET i = 0;

    WHILE i < p_orders DO
        SET v_customer  = v_first_new_customer + FLOOR(RAND() * p_customers);
        SET v_product_a = FLOOR(1 + RAND() * 15);
        SET v_product_b = MOD(v_product_a + FLOOR(RAND() * 14), 15) + 1;

        CALL place_order(
            v_customer,
            JSON_ARRAY(
                JSON_OBJECT('product_id', v_product_a, 'quantity', FLOOR(1 + RAND() * 25)),
                JSON_OBJECT('product_id', v_product_b, 'quantity', FLOOR(1 + RAND() * 5))
            ),
            v_order_id
        );

        SET i = i + 1;
    END WHILE;

    UPDATE orders
       SET order_date = order_date - INTERVAL FLOOR(RAND() * 730) DAY
     WHERE customer_id >= v_first_new_customer;

    UPDATE inventory_logs il
      JOIN orders o ON o.order_id = il.order_id
       SET il.changed_at = o.order_date
     WHERE o.customer_id >= v_first_new_customer;
END$$


DELIMITER ;


CALL generate_load_test_data(3000, 10000);


SELECT
    (SELECT COUNT(*) FROM customers)      AS customers,
    (SELECT COUNT(*) FROM orders)         AS orders,
    (SELECT COUNT(*) FROM order_details)  AS order_lines,
    (SELECT COUNT(*) FROM inventory_logs) AS log_entries;