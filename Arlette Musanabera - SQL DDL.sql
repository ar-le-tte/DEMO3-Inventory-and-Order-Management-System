-- ==========================================
-- Step 2: Schema Implementation (DDL)
-- Inventory & Order Management System
-- ==========================================

-- (1, 2. 3) CREATING THE TABLES & DATA INTEGRITY & KEYS
-- FOR RERUNS (with cascade to consider dependents)
DROP TABLE IF EXISTS order_items CASCADE; 
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- -------------------------
-- 1) Customers
-- -------------------------
CREATE TABLE customers (
  customer_id       SERIAL PRIMARY KEY,
  full_name         VARCHAR(150) NOT NULL,
  email             VARCHAR(255) NOT NULL UNIQUE,
  phone             VARCHAR(30),
  shipping_address  VARCHAR(300) NOT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------
-- 2) Products
-- -------------------------
CREATE TABLE products (
  product_id     SERIAL PRIMARY KEY,
  product_name   VARCHAR(200) NOT NULL,
  category       VARCHAR(80)  NOT NULL,
  price_usd      NUMERIC(10,2) NOT NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_products_price_nonnegative CHECK (price_usd >= 0)
);

-- -------------------------
-- 3) Inventory (1 row per product)
-- -------------------------
CREATE TABLE inventory (
  product_id        INT PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
  quantity_on_hand  INT NOT NULL,
  last_updated      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_inventory_qty_nonnegative CHECK (quantity_on_hand >= 0)
);

-- -------------------------
-- 4) Orders
-- -------------------------
CREATE TABLE orders (
  order_id            SERIAL PRIMARY KEY,
  customer_id         INT NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
  order_date          DATE NOT NULL DEFAULT CURRENT_DATE,
  total_order_amount  NUMERIC(10,2) NOT NULL DEFAULT 0,
  order_status        VARCHAR(20) NOT NULL DEFAULT 'Pending',
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT chk_orders_total_nonnegative CHECK (total_order_amount >= 0),
  CONSTRAINT chk_orders_status_valid CHECK (order_status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled'))
);

-- -------------------------
-- 5) Order Items
-- This is a bridge table
-- -------------------------
CREATE TABLE order_items (
  order_id           INT NOT NULL REFERENCES orders(order_id) ON DELETE RESTRICT,
  product_id         INT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
  quantity           INT NOT NULL,
  price_at_purchase  NUMERIC(10,2) NOT NULL,

  CONSTRAINT pk_order_items PRIMARY KEY (order_id, product_id),
  CONSTRAINT chk_order_items_qty_positive CHECK (quantity > 0),
  CONSTRAINT chk_order_items_price_nonnegative CHECK (price_at_purchase >= 0)
);

-- INDEXES FOR EASY IDENTIFICATION ON THE TABLE THAT HAS TWO PRIMARY KEYS
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- (4) POPULATING THE TABLES

-- CUSTOMERS
INSERT INTO customers (customer_id, full_name, email, phone, shipping_address, created_at) VALUES
(1017, 'Carine Idani', 'carine.idani@example.com', '+250788000001', 'Kigali, Rwanda', NOW()),
(1897, 'Cedric Nkurunziza', 'cedric.nkurunziza@example.com', '+250788000021', 'Gicumbi, Rwanda', NOW()),
(1941, 'Sandrine Mukeshimana', 'sandrine.mukeshimana@example.com', '+250788000022', 'Kigali, Rwanda', NOW()),
(1986, 'Innocent Rukundo', 'innocent.rukundo@example.com', '+250788000023', 'Karongi, Rwanda', NOW()),
(2033, 'Esther Mukantwali', 'esther.mukantwali@example.com', '+250788000024', 'Nyanza, Rwanda', NOW()),
(2089, 'Kevin Nsengiyumva', 'kevin.nsengiyumva@example.com', '+250788000025', 'Kigali, Rwanda', NOW()),
(1042, 'Arlette Musanabera', 'arlette.musanabera@example.com', '+250788000002', 'Kigali, Rwanda', NOW()),
(1189, 'Eric Mugisha', 'eric.mugisha@example.com', '+250788000005', 'Rubavu, Rwanda', NOW()),
(1234, 'Alice Uwimana', 'alice.uwimana@example.com', '+250788000006', 'Rwamagana, Rwanda', NOW()),
(1276, 'Jean Claude Ndayishimiye', 'jeanclaude.ndayishimiye@example.com', '+250788000007', 'Kigali, Rwanda', NOW()),
(1311, 'Aline Mukamana', 'aline.mukamana@example.com', '+250788000008', 'Muhanga, Rwanda', NOW()),
(1367, 'Patrick Habimana', 'patrick.habimana@example.com', '+250788000009', 'Nyagatare, Rwanda', NOW()),
(1402, 'Grace Uwera', 'grace.uwera@example.com', '+250788000010', 'Kigali, Rwanda', NOW()),
(1098, 'Damas Niyonkuru', 'damas.niyonkuru@example.com', '+250788000003', 'Huye, Rwanda', NOW()),
(1125, 'Marina Ihirwe Ndoro', 'marina.ihirwe.ndoro@example.com', '+250788000004', 'Musanze, Rwanda', NOW()),
(1459, 'Samuel Bizimana', 'samuel.bizimana@example.com', '+250788000011', 'Gisenyi, Rwanda', NOW()),
(1493, 'Clarisse Nyirabagenzi', 'clarisse.nyirabagenzi@example.com', '+250788000012', 'Kigali, Rwanda', NOW()),
(1528, 'Emmanuel Tuyishime', 'emmanuel.tuyishime@example.com', '+250788000013', 'Kayonza, Rwanda', NOW()),
(1574, 'Diane Mutoni', 'diane.mutoni@example.com', '+250788000014', 'Huye, Rwanda', NOW()),
(1610, 'Yves Habyarimana', 'yves.habyarimana@example.com', '+250788000015', 'Ruhengeri, Rwanda', NOW()),
(1666, 'Chantal Nishimwe', 'chantal.nishimwe@example.com', '+250788000016', 'Kigali, Rwanda', NOW()),
(1709, 'Alexis Jenoside', 'alexis.jenoside@example.com', '+250788000017', 'Rusizi, Rwanda', NOW()),
(1751, 'Olivia Ingabire', 'olivia.ingabire@example.com', '+250788000018', 'Nyamata, Rwanda', NOW()),
(1798, 'Fabrice Nzeyimana', 'fabrice.nzeyimana@example.com', '+250788000019', 'Kigali, Rwanda', NOW()),
(1843, 'Beatrice Uwamahoro', 'beatrice.uwamahoro@example.com', '+250788000020', 'Bugesera, Rwanda', NOW());


SELECT customer_id, full_name, email
FROM customers;
-- PRODUCTS
INSERT INTO products (product_id, product_name, category, price_usd, created_at) VALUES
(3012, 'Wireless Mouse', 'Digital Gadgets', 15.99, '2024-03-12 10:20:00'),
(3077, 'Unisex Hoodie', 'Clothes', 29.99, '2024-04-18 13:40:00'),
(3129, 'Silver Necklace', 'Jewelry', 45.00, '2024-03-28 11:15:00'),
(3184, 'Yoga Mat', 'Sports', 18.00, '2024-02-07 09:10:00'),
(3241, 'Running Shoes', 'Shoes', 60.00, '2024-08-25 17:05:00'),
(3356, 'USB-C Fast Charger', 'Digital Gadgets', 19.50, '2024-05-06 14:45:00'),
(3410, 'Cotton T-Shirt', 'Clothes', 12.50, '2024-06-09 08:50:00'),
(3473, 'Gold-Plated Bracelet', 'Jewelry', 38.50, '2024-05-17 16:05:00'),
(3528, 'Football', 'Sports', 22.00, '2024-01-19 14:35:00'),
(3599, 'Smartwatch', 'Digital Gadgets', 85.00, '2024-09-02 16:10:00'),
(3651, 'Denim Jeans', 'Clothes', 42.00, '2024-11-03 10:25:00'),
(3716, 'Portable Power Bank', 'Digital Gadgets', 27.90, '2024-10-21 11:55:00'),
(3782, 'Baseball Cap', 'Clothes', 9.99, '2024-12-12 15:40:00'),
(3837, 'Bluetooth Headphones', 'Digital Gadgets', 55.00, '2024-07-18 09:30:00');


SELECT product_id, product_name, category, price_usd
FROM products
ORDER BY product_id;

--INVENTORY
INSERT INTO inventory (product_id, quantity_on_hand, last_updated)
SELECT
  product_id,
  (random() * 200)::int AS quantity_on_hand,
  NOW() AS last_updated
FROM products;

-- ORDERS (We will first set the amount to zero to be updated later)
INSERT INTO orders (order_id, customer_id, order_date, total_order_amount, order_status, created_at) VALUES
(5001, 1017, '2024-06-14', 0, 'Delivered', '2024-06-14 10:42:00'),
(5002, 1042, '2024-07-03', 0, 'Shipped',   '2024-07-03 14:18:00'),
(5003, 1098, '2024-08-21', 0, 'Delivered', '2024-08-21 09:55:00'),
(5004, 1125, '2024-09-02', 0, 'Pending',   '2024-09-02 16:07:00'),
(5005, 1189, '2024-09-18', 0, 'Delivered', '2024-09-18 11:33:00'),
(5006, 1234, '2024-10-05', 0, 'Shipped',   '2024-10-05 15:41:00'),
(5007, 1276, '2024-10-29', 0, 'Delivered', '2024-10-29 08:26:00'),
(5017, 1042, '2025-03-15', 0, 'Delivered', '2025-03-15 11:46:00'),
(5008, 1311, '2024-11-11', 0, 'Pending',   '2024-11-11 17:02:00'),
(5009, 1367, '2024-11-24', 0, 'Delivered', '2024-11-24 13:19:00'),
(5010, 1402, '2024-12-06', 0, 'Shipped',   '2024-12-06 09:48:00'),
(5011, 1459, '2024-12-19', 0, 'Delivered', '2024-12-19 18:05:00'),
(5012, 1493, '2025-01-04', 0, 'Pending',   '2025-01-04 12:11:00'),
(5013, 1528, '2025-01-17', 0, 'Delivered', '2025-01-17 10:37:00'),
(5014, 1574, '2025-02-02', 0, 'Shipped',   '2025-02-02 14:54:00'),
(5015, 1610, '2025-02-18', 0, 'Delivered', '2025-02-18 09:22:00'),
(5016, 1017, '2025-03-01', 0, 'Pending',   '2025-03-01 16:30:00');

SELECT * FROM orders;

-- ORDER ITEMS
WITH items(order_id, product_id, quantity) AS (
  VALUES
    (5001, 3012, 2), (5001, 3077, 1), (5002, 3129, 1),
    (5002, 3184, 2), (5003, 3241, 1), (5004, 3356, 3),
    (5005, 3410, 2), (5005, 3473, 1), (5006, 3528, 1),
    (5006, 3599, 1), (5007, 3651, 2), (5008, 3716, 1),
    (5008, 3782, 2), (5009, 3837, 1), (5010, 3012, 1),
    (5010, 3241, 1), (5011, 3129, 2), (5012, 3356, 1), 
    (5013, 3410, 3), (5014, 3473, 1), (5014, 3528, 2),
    (5015, 3599, 1), (5016, 3651, 2), (5016, 3782, 1),
    (5017, 3837, 2)),
missing_products AS (
  SELECT DISTINCT i.product_id
  FROM items i
  LEFT JOIN products p ON p.product_id = i.product_id
  WHERE p.product_id IS NULL
)
INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase)
SELECT
  i.order_id,
  i.product_id,
  i.quantity,
  p.price_usd
FROM items i
JOIN products p ON p.product_id = i.product_id
WHERE NOT EXISTS (SELECT 1 FROM missing_products);
