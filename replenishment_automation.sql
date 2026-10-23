USE inventory_mgt;

DROP PROCEDURE IF EXISTS replenish_product;
DROP PROCEDURE IF EXISTS replenish_low_stock;
DROP PROCEDURE IF EXISTS refresh_customer_tiers;
DROP TRIGGER   IF EXISTS trg_orders_au;
DROP EVENT     IF EXISTS ev_daily_replenishment;


DELIMITER $$


CREATE PROCEDURE replenish_product(
    IN p_product_id INT,
    IN p_quantity   INT,
    IN p_note       VARCHAR(255)
)
BEGIN
    DECLARE v_stock_before INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replenishment quantity must be a positive whole number';
    END IF;

    START TRANSACTION;

        SELECT stock_quantity INTO v_stock_before
          FROM products
         WHERE product_id = p_product_id
           FOR UPDATE;

        IF v_stock_before IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product does not exist';
        END IF;

        UPDATE products
           SET stock_quantity = stock_quantity + p_quantity
         WHERE product_id = p_product_id;

        INSERT INTO inventory_logs
            (product_id, change_type, quantity_change, stock_before, stock_after, note)
        VALUES
            (p_product_id, 'REPLENISHMENT', p_quantity, v_stock_before,
             v_stock_before + p_quantity, COALESCE(p_note, 'Manual replenishment'));

    COMMIT;
END$$


CREATE PROCEDURE replenish_low_stock(OUT p_products_replenished INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS tmp_restock;
        RESIGNAL;
    END;

    DROP TEMPORARY TABLE IF EXISTS tmp_restock;
    CREATE TEMPORARY TABLE tmp_restock (
        product_id   INT PRIMARY KEY,
        stock_before INT,
        restock_qty  INT
    );

    START TRANSACTION;

        INSERT INTO tmp_restock (product_id, stock_before, restock_qty)
        SELECT product_id, stock_quantity, reorder_level * 2 - stock_quantity
          FROM products
         WHERE stock_quantity <= reorder_level
           AND reorder_level > 0
           FOR UPDATE;

        UPDATE products p
          JOIN tmp_restock t ON t.product_id = p.product_id
           SET p.stock_quantity = p.stock_quantity + t.restock_qty;

        INSERT INTO inventory_logs
            (product_id, change_type, quantity_change, stock_before, stock_after, note)
        SELECT product_id, 'REPLENISHMENT', restock_qty, stock_before,
               stock_before + restock_qty, 'Automatic restock to 2x reorder level'
          FROM tmp_restock;

        SELECT COUNT(*) INTO p_products_replenished FROM tmp_restock;

    COMMIT;

    DROP TEMPORARY TABLE IF EXISTS tmp_restock;
END$$


CREATE PROCEDURE refresh_customer_tiers()
BEGIN
    UPDATE customers c
      LEFT JOIN (
            SELECT customer_id, SUM(total_amount) AS total_spent
              FROM orders
             GROUP BY customer_id
      ) s ON s.customer_id = c.customer_id
       SET c.tier = fn_customer_tier(COALESCE(s.total_spent, 0));
END$$


CREATE TRIGGER trg_orders_au
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE v_total_spent DECIMAL(12,2);

    IF NEW.total_amount <> OLD.total_amount THEN
        SELECT COALESCE(SUM(total_amount), 0) INTO v_total_spent
          FROM orders
         WHERE customer_id = NEW.customer_id;

        UPDATE customers
           SET tier = fn_customer_tier(v_total_spent)
         WHERE customer_id = NEW.customer_id;
    END IF;
END$$


CREATE EVENT ev_daily_replenishment
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 6 HOUR)
DO
BEGIN
    CALL replenish_low_stock(@replenished_count);
END$$


DELIMITER ;