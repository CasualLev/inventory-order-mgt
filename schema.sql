-- =============================================================
-- Phase 1: Database Design and Schema Implementation
-- Inventory and Order Management System
-- =============================================================

CREATE DATABASE IF NOT EXISTS inventory_mgt;
USE inventory_mgt;

-- Drop tables in REVERSE dependency order so the script can be
-- re-run safely (children before parents, or foreign keys block the drop).
DROP TABLE IF EXISTS inventory_logs;
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;

-- -------------------------------------------------------------
-- PRODUCTS: what we sell and how much we have
-- -------------------------------------------------------------
CREATE TABLE products (
    product_id      INT AUTO_INCREMENT PRIMARY KEY,
    product_name    VARCHAR(100)  NOT NULL,
    category        VARCHAR(50)   NOT NULL,
    price           DECIMAL(10,2) NOT NULL,
    stock_quantity  INT           NOT NULL DEFAULT 0,
    reorder_level   INT           NOT NULL DEFAULT 10,
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_products_price   CHECK (price >= 0),
    CONSTRAINT chk_products_stock   CHECK (stock_quantity >= 0),   -- can never oversell
    CONSTRAINT chk_products_reorder CHECK (reorder_level >= 0)
);

-- -------------------------------------------------------------
-- CUSTOMERS: who buys from us
-- -------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50)   NOT NULL,
    last_name       VARCHAR(50)   NOT NULL,
    email           VARCHAR(100)  NOT NULL,
    phone           VARCHAR(20),                       -- text, not a number: keeps '+' and leading zeros
    tier            ENUM('Bronze','Silver','Gold') NOT NULL DEFAULT 'Bronze',  -- maintained automatically in Phase 4
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_customers_email UNIQUE (email)       -- no two customers share an email
);

-- -------------------------------------------------------------
-- ORDERS: one row per purchase (the "receipt header")
-- -------------------------------------------------------------
CREATE TABLE orders (
    order_id        INT AUTO_INCREMENT PRIMARY KEY,
    customer_id     INT           NOT NULL,
    order_date      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0.00,   -- calculated automatically in Phase 2

    CONSTRAINT chk_orders_total CHECK (total_amount >= 0),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT          -- can't delete a customer who has orders
        ON UPDATE CASCADE
);

-- -------------------------------------------------------------
-- ORDER_DETAILS: one row per product within an order (the "receipt lines")
-- -------------------------------------------------------------
CREATE TABLE order_details (
    order_detail_id  INT AUTO_INCREMENT PRIMARY KEY,
    order_id         INT           NOT NULL,
    product_id       INT           NOT NULL,
    quantity         INT           NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL,              -- price AT TIME OF PURCHASE
    discount_percent DECIMAL(5,2)  NOT NULL DEFAULT 0.00, -- bulk discount (Phase 3)
    line_total       DECIMAL(12,2) AS
        (ROUND(quantity * unit_price * (1 - discount_percent / 100), 2)) STORED,

    CONSTRAINT chk_od_quantity CHECK (quantity > 0),
    CONSTRAINT chk_od_price    CHECK (unit_price >= 0),
    CONSTRAINT chk_od_discount CHECK (discount_percent BETWEEN 0 AND 100),
    CONSTRAINT uq_od_order_product UNIQUE (order_id, product_id),  -- one line per product per order
    CONSTRAINT fk_od_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE,          -- delete an order -> its lines go with it
    CONSTRAINT fk_od_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON DELETE RESTRICT          -- can't delete a product that has been sold
);

-- -------------------------------------------------------------
-- INVENTORY_LOGS: audit trail of every stock change
-- -------------------------------------------------------------
CREATE TABLE inventory_logs (
    log_id           INT AUTO_INCREMENT PRIMARY KEY,
    product_id       INT          NOT NULL,
    change_type      ENUM('ORDER','REPLENISHMENT','ADJUSTMENT') NOT NULL,
    quantity_change  INT          NOT NULL,   -- negative = stock out, positive = stock in
    stock_before     INT          NOT NULL,
    stock_after      INT          NOT NULL,
    order_id         INT          NULL,       -- filled only when the change came from an order
    note             VARCHAR(255),
    changed_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_logs_math CHECK (stock_after = stock_before + quantity_change),
    CONSTRAINT fk_logs_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON DELETE RESTRICT,         -- never lose audit history
    CONSTRAINT fk_logs_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE SET NULL          -- keep the log even if the order is removed
);

-- Quick check: list the tables you just created
SHOW TABLES; 