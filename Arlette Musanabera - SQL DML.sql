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

