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
  order_id           INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
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

