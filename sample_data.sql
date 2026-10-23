-- =============================================================
-- Sample products and customers to test the system with.
--
-- Run AFTER schema.sql.
--
-- NOTE: No orders are inserted here on purpose. 
-- =============================================================

USE inventory_mgt;


INSERT INTO products (product_name, category, price, stock_quantity, reorder_level) VALUES
-- Electronics
('Wireless Mouse',            'Electronics',  25.00, 120, 20),
('Mechanical Keyboard',       'Electronics',  85.00,  40, 10),
('USB-C Charger 65W',         'Electronics',  45.00,   8, 15),   -- LOW
('Bluetooth Headphones',      'Electronics', 120.00,  25, 10),
('27-inch Monitor',           'Electronics', 280.00,  12,  5),
-- Stationery
('A4 Notebook (Pack of 5)',   'Stationery',    9.50, 300, 50),
('Ballpoint Pens (Box of 12)','Stationery',    6.00,  45, 60),   -- LOW
('Desk Organizer',            'Stationery',   18.00,  35, 10),
('Sticky Notes (Pack of 6)',  'Stationery',    4.50, 200, 40),
-- Home & Kitchen
('Stainless Water Bottle',    'Home & Kitchen', 15.00, 150, 30),
('Coffee Mug Set (4 pcs)',    'Home & Kitchen', 22.00,  10, 10),  -- AT reorder level
('Electric Kettle',           'Home & Kitchen', 38.00,  30,  8),
-- Sports
('Yoga Mat',                  'Sports',        28.00,  60, 15),
('Resistance Bands Set',      'Sports',        19.00,   5, 12),   -- LOW
('Running Water Belt',        'Sports',        16.00,  70, 15);

-- -------------------------------------------------------------
-- CUSTOMERS (10 people). Everyone starts as Bronze; tiers are
-- updated automatically from spending later on.
-- -------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, phone) VALUES
('Alice',   'Uwase',     'alice.uwase@example.com',     '+250788100001'),
('Brian',   'Otieno',    'brian.otieno@example.com',    '+254712100002'),
('Chloe',   'Martin',    'chloe.martin@example.com',    '+33612100003'),
('David',   'Mensah',    'david.mensah@example.com',    '+233241100004'),
('Esther',  'Ndayisaba', 'esther.ndayisaba@example.com','+250722100005'),
('Farid',   'Haddad',    'farid.haddad@example.com',    '+971501100006'),
('Grace',   'Kim',       'grace.kim@example.com',       '+821012100007'),
('Henry',   'Okafor',    'henry.okafor@example.com',    '+234803100008'),
('Ivy',     'Johnson',   'ivy.johnson@example.com',     NULL),          -- phone is optional
('Jean',    'Habimana',  'jean.habimana@example.com',   '+250789100010');

-- -------------------------------------------------------------
-- OPENING STOCK LOG
-- Record the starting stock of every product as the first entry
-- in the audit trail, so the log explains ALL stock from day one.
-- INSERT ... SELECT creates one log row per product in one statement.
-- -------------------------------------------------------------
INSERT INTO inventory_logs
    (product_id, change_type, quantity_change, stock_before, stock_after, note)
SELECT
    product_id,
    'ADJUSTMENT',
    stock_quantity,
    0,
    stock_quantity,
    'Opening stock'
FROM products;

-- -------------------------------------------------------------
-- Quick checks
-- -------------------------------------------------------------
SELECT COUNT(*) AS product_count  FROM products;
SELECT COUNT(*) AS customer_count FROM customers;
SELECT COUNT(*) AS log_count      FROM inventory_logs;

-- Preview: which products are already at or below reorder level?
SELECT product_name, stock_quantity, reorder_level
FROM products
WHERE stock_quantity <= reorder_level;