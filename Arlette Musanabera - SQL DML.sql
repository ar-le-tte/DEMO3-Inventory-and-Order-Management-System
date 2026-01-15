-- ========================================================
-- Step 3: KPI + Advanced SQL Querying.
-- ========================================================

-- Let us first update the Total amount in orders to match the order items and their quantity prices
UPDATE orders o
SET total_order_amount = x.total_amount
FROM (
  SELECT
    oi.order_id,
    ROUND(SUM(oi.quantity * oi.price_at_purchase)::numeric, 2) AS total_amount
  FROM order_items oi
  GROUP BY oi.order_id
) x
WHERE o.order_id = x.order_id;


SELECT order_id, total_order_amount
FROM orders
ORDER BY order_id;


-- BUSINESS KPIs

--1. Total Revenue (From Shipped or Delivered)
SELECT ROUND(SUM(total_order_amount)::numeric, 2) AS total_revenue_usd
FROM orders
WHERE order_status IN ('Shipped', 'Delivered');

--2. Top 10 Customers by Total Spending
SELECT c.full_name AS "Customer Name", ROUND(SUM(o.total_order_amount)::numeric, 2) AS "Total Amount Spent"
FROM customers c
JOIN orders o
  ON o.customer_id = c.customer_id
WHERE o.order_status IN ('Shipped', 'Delivered')
GROUP BY c.customer_id, c.full_name
ORDER BY "Total Amount Spent" DESC
LIMIT 10;

--3. Top 5 Best-Selling Products by Quantity Sold
SELECT p.product_name AS "Product Name" ,
  SUM(oi.quantity) AS "Total Quantity Sold"
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status IN ('Shipped', 'Delivered')
GROUP BY p.product_id, "Product Name"
ORDER BY  "Total Quantity Sold" DESC
LIMIT 5;

-- 4. Monthly Sales Trend
SELECT TO_CHAR(DATE_TRUNC('month', o.order_date), 'YYYY-MM') AS "Month",
  ROUND(SUM(o.total_order_amount)::numeric, 2) AS "Monthly Revenue (USD)"
FROM orders o
WHERE o.order_status IN ('Shipped', 'Delivered')
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY DATE_TRUNC('month', o.order_date);

-- ANALYTICAL QUERIES

-- 1. Sales Rank by Category
WITH product_sales AS (
  SELECT p.category, p.product_id, p.product_name,
    SUM(oi.quantity * oi.price_at_purchase) AS revenue
  FROM order_items oi
  JOIN orders o   ON o.order_id = oi.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.order_status IN ('Shipped', 'Delivered')
  GROUP BY p.category, p.product_id, p.product_name
),
ranked AS (
  SELECT category, product_name, revenue,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
  FROM product_sales
)
SELECT category,product_name,
   ROUND(revenue::numeric, 2) AS revenue_usd,
  rank_in_category AS sales_rank_in_category,
  '#' || rank_in_category || ' in ' || category AS category_rank_label
FROM ranked
ORDER BY category, rank_in_category, revenue DESC;

-- 2. Customer Order Frequency
SELECT c.full_name, o.order_id, o.order_date,
  LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS previous_order_date
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY c.full_name, o.order_date;

-- PERFORMANCE OPTIMIZATION

-- 1. CustomerSalesSummary
CREATE OR REPLACE VIEW CustomerSalesSummary AS
SELECT c.customer_id, c.full_name,
  COUNT(o.order_id) AS total_orders,
  ROUND(COALESCE(SUM(o.total_order_amount), 0)::numeric, 2) AS total_amount_spent_usd
FROM customers c
LEFT JOIN orders o
  ON o.customer_id = c.customer_id
 AND o.order_status IN ('Shipped', 'Delivered')
GROUP BY c.customer_id;

SELECT *
FROM CustomerSalesSummary
ORDER BY total_amount_spent_usd DESC
LIMIT 10;

-- 2. Stored Procedure
CREATE OR REPLACE PROCEDURE ProcessNewOrder(
  IN CustomerID INT,  -- Customer ID
  IN ProductID  INT,  -- Product ID
  IN quantity    INT   -- Quantity
)
LANGUAGE plpgsql
AS $$
DECLARE
  stock    INT;
  price    NUMERIC(10,2);
  v_order_id INT;
BEGIN
  -- Quantity Validation
  IF quantity <= 0 THEN
    RAISE EXCEPTION 'Please enter a non-zero quantity';
  END IF;

  -- Checking available inventory and locking row
  SELECT quantity_on_hand
  INTO stock
  FROM inventory
  WHERE inventory.product_id = product_id
  FOR UPDATE;

  IF stock IS NULL THEN
    RAISE EXCEPTION 'Product % not found in inventory', product_id;
  END IF;

  IF stock < quantity THEN
    RAISE EXCEPTION
      'Insufficient stock for product %. Available: %, Requested: %',
      ProductID, stock, quantity;
  END IF;

  -- Price
  SELECT price_usd
  INTO price
  FROM products
  WHERE products.product_id = ProductID;

  IF price IS NULL THEN
    RAISE EXCEPTION 'Product % not found in products table', product_id;
  END IF;

  -- Now We Create The Order
  INSERT INTO orders (customer_id, order_date, total_order_amount, order_status, created_at)
  VALUES (CustomerID, CURRENT_DATE, 0, 'Pending', CURRENT_TIMESTAMP)
  RETURNING order_id INTO v_order_id;

  -- Now the order items
  INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase)
  VALUES (v_order_id, ProductID, quantity, price);

  -- Reducting the ordered items from the available stock (Inventory Update)
  UPDATE inventory
  SET quantity_on_hand = quantity_on_hand - quantity,
      last_updated = CURRENT_TIMESTAMP
  WHERE inventory.product_id = ProductID;

  -- Updating the order total with our price*the quantity ordered
  UPDATE orders
  SET total_order_amount = ROUND((quantity * price)::numeric, 2)
  WHERE order_id = v_order_id;

END;
$$;

CALL ProcessNewOrder(1311, 3012, 2);


select * from order_items;