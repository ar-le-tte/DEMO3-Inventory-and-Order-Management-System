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

