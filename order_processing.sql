

USE inventory_mgt;

DROP FUNCTION  IF EXISTS fn_bulk_discount;
DROP TRIGGER   IF EXISTS trg_order_details_ai;
DROP PROCEDURE IF EXISTS place_order;

-- DELIMITER tells the client to stop treating ';' as "end of statement",
-- so the semicolons INSIDE the function/trigger/procedure bodies don't
-- cut them off early. We switch back to ';' at the end.
DELIMITER $$




CREATE FUNCTION fn_bulk_discount(p_quantity INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CASE
        WHEN p_quantity >= 50 THEN 15.00
        WHEN p_quantity >= 20 THEN 10.00
        WHEN p_quantity >= 10 THEN  5.00
        ELSE 0.00
    END;
END$$






CREATE TRIGGER trg_order_details_ai
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    DECLARE v_stock_before INT;
    DECLARE v_product_name VARCHAR(100);
    DECLARE v_msg          VARCHAR(255);

   


    SELECT stock_quantity, product_name
      INTO v_stock_before, v_product_name
      FROM products
     WHERE product_id = NEW.product_id
       FOR UPDATE;

    IF v_stock_before < NEW.quantity THEN
        SET v_msg = CONCAT('Insufficient stock for "', v_product_name,
                           '": requested ', NEW.quantity,
                           ', available ', v_stock_before);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    UPDATE products
       SET stock_quantity = stock_quantity - NEW.quantity
     WHERE product_id = NEW.product_id;

    INSERT INTO inventory_logs
        (product_id, change_type, quantity_change, stock_before, stock_after, order_id, note)
    VALUES
        (NEW.product_id, 'ORDER', -NEW.quantity, v_stock_before,
         v_stock_before - NEW.quantity, NEW.order_id,
         CONCAT('Sold in order #', NEW.order_id));

    UPDATE orders
       SET total_amount = total_amount + NEW.line_total
     WHERE order_id = NEW.order_id;
END$$





CREATE PROCEDURE place_order(
    IN  p_customer_id INT,
    IN  p_items       JSON,
    OUT p_order_id    INT
)
BEGIN
    DECLARE v_count INT;

    -- If ANYTHING fails (our own checks, the trigger's stock check,
    -- a constraint), undo everything and pass the error to the caller.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS tmp_order_items;
        SET p_order_id = NULL;
        RESIGNAL;
    END;

    SET p_order_id = NULL;

    -- ---- Validate the input before touching any data ----
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer does not exist';
    END IF;

    IF p_items IS NULL OR JSON_TYPE(p_items) <> 'ARRAY' OR JSON_LENGTH(p_items) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Items must be a non-empty JSON array of {"product_id", "quantity"}';
    END IF;




    DROP TEMPORARY TABLE IF EXISTS tmp_order_items;
    CREATE TEMPORARY TABLE tmp_order_items (
        product_id INT,
        quantity   INT,
        unit_price DECIMAL(10,2)
    );

    INSERT INTO tmp_order_items (product_id, quantity, unit_price)
    SELECT j.product_id, j.quantity, p.price
      FROM JSON_TABLE(p_items, '$[*]' COLUMNS (
               product_id INT PATH '$.product_id',
               quantity   INT PATH '$.quantity'
           )) AS j
      LEFT JOIN products p ON p.product_id = j.product_id;

    SELECT COUNT(*) INTO v_count FROM tmp_order_items WHERE unit_price IS NULL;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'One or more products do not exist';
    END IF;

    SELECT COUNT(*) INTO v_count FROM tmp_order_items WHERE quantity IS NULL OR quantity <= 0;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Every quantity must be a positive whole number';
    END IF;

    SELECT COUNT(*) - COUNT(DISTINCT product_id) INTO v_count FROM tmp_order_items;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The same product appears twice; combine it into one line';
    END IF;

    -- ---- All checks passed: do the real work atomically ----
    START TRANSACTION;

        INSERT INTO orders (customer_id) VALUES (p_customer_id);
        SET p_order_id = LAST_INSERT_ID();

        -- One INSERT for all lines. The trigger fires once per line:
        -- stock deducted, log written, order total updated.
        INSERT INTO order_details (order_id, product_id, quantity, unit_price, discount_percent)
        SELECT p_order_id, product_id, quantity, unit_price, fn_bulk_discount(quantity)
          FROM tmp_order_items;

    COMMIT;

    DROP TEMPORARY TABLE IF EXISTS tmp_order_items;
END$$

DELIMITER ;