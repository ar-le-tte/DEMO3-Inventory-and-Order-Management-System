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
  IN CustomerID  INT,    
  IN ProductIDs  INT[],   -- List of Product IDs
  IN Quantities  INT[]    -- Corresponding quantities
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_id   INT;
  v_total      NUMERIC(10,2);
  v_len_p      INT;
  v_len_q      INT;
  v_missing_products text;
  v_short_msg text;

BEGIN
  -- Input Validation
  IF NOT EXISTS (
    SELECT 1
    FROM customers
    WHERE customer_id = CustomerID
  ) THEN
    RAISE EXCEPTION 'Customer % does not exist', CustomerID;
  END IF;

  v_len_p := COALESCE(array_length(ProductIDs, 1), 0);
  v_len_q := COALESCE(array_length(Quantities, 1), 0);

  IF v_len_p = 0 OR v_len_q = 0 THEN
    RAISE EXCEPTION 'ProductIDs and Quantities must not be empty';
  END IF;

  IF v_len_p <> v_len_q THEN
    RAISE EXCEPTION 'ProductIDs and Quantities must have the same length';
  END IF;

  IF EXISTS (
    SELECT 1 FROM unnest(Quantities) q WHERE q <= 0
  ) THEN
    RAISE EXCEPTION 'All quantities must be greater than zero';
  END IF;

  -- Checking available inventory and locking row
	WITH items AS (SELECT x.product_id, SUM(x.qty) AS qty
	  FROM unnest(ProductIDs, Quantities) AS x(product_id, qty)
	  GROUP BY x.product_id),
	shortage AS (
	  SELECT i.product_id, i.qty AS requested_qty, inv.quantity_on_hand AS available_qty
	  FROM items i
	  JOIN inventory inv ON inv.product_id = i.product_id
      WHERE inv.quantity_on_hand < i.qty
	  FOR UPDATE)
	SELECT
	  string_agg(format('product_id=%s (requested=%s, available=%s)',
	           product_id, requested_qty, available_qty),'; ')
	INTO v_short_msg
	FROM shortage;
	
	IF v_short_msg IS NOT NULL THEN
	  RAISE EXCEPTION 'Insufficient stock: %', v_short_msg;
	END IF;


  -- Ensuring that all products exist in inventory
	SELECT string_agg(p.product_id::text, ', ')
	INTO v_missing_products
	FROM ( SELECT DISTINCT product_id
	  FROM unnest(ProductIDs) AS t(product_id)) p
	LEFT JOIN inventory inv
	  ON inv.product_id = p.product_id
	WHERE inv.product_id IS NULL;
	
	IF v_missing_products IS NOT NULL THEN
	  RAISE EXCEPTION 'The following product_id(s) do not exist in inventory: %', v_missing_products;
	END IF;


  -- Now let us create the order
  INSERT INTO orders (customer_id, order_date, total_order_amount, order_status, created_at)
  VALUES (CustomerID, CURRENT_DATE, 0, 'Pending', CURRENT_TIMESTAMP)
  RETURNING order_id INTO v_order_id;

  -- Now the order items
  WITH items AS (SELECT x.product_id, SUM(x.qty) AS qty
    FROM unnest(ProductIDs, Quantities) AS x(product_id, qty)
    GROUP BY x.product_id)
  INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase)
  SELECT v_order_id, i.product_id, i.qty, p.price_usd
  FROM items i
  JOIN products p ON p.product_id = i.product_id;

-- Deducting the ordered items from the available stock (Inventory Update)
  WITH items AS (
    SELECT x.product_id, SUM(x.qty) AS qty
    FROM unnest(ProductIDs, Quantities) AS x(product_id, qty)
    GROUP BY x.product_id)
  UPDATE inventory inv
  SET quantity_on_hand = inv.quantity_on_hand - i.qty,
      last_updated = CURRENT_TIMESTAMP
  FROM items i
  WHERE inv.product_id = i.product_id;

  -- Updating the order total with our price*the quantity ordered
  SELECT ROUND(SUM(oi.quantity * oi.price_at_purchase)::numeric, 2)
  INTO v_total
  FROM order_items oi
  WHERE oi.order_id = v_order_id;

  UPDATE orders
  SET total_order_amount = COALESCE(v_total, 0)
  WHERE order_id = v_order_id;

END;
$$;


CALL ProcessNewOrder(1017,
  ARRAY[3012, 3077, 3599],
  ARRAY[2,    1,    1]);


select * from order_items;