
-- Advanced SQL Queries for Olist E-Commerce Data


-- Average Review Score per Product Category
SELECT p.product_category_name, AVG(r.review_score) AS avg_score
FROM olist_order_reviews r
JOIN olist_orders o ON r.order_id = o.order_id
JOIN olist_order_items i ON o.order_id = i.order_id
JOIN olist_products p ON i.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_score DESC;


-- Product More Expensive than Overall Average
SELECT product_id, price
FROM olist_order_items
WHERE price > (SELECT AVG(price) FROM olist_order_items);


-- Average Delivery Time
WITH delivery_times AS (
    SELECT order_id,
           DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delivery_days
    FROM olist_orders
    WHERE order_status = 'delivered'
)
SELECT AVG(delivery_days) AS avg_delivery_days
FROM delivery_times;


-- Average Delivery Time per Product Category
SELECT 
    p.product_category_name,
    AVG(DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
JOIN olist_products p ON i.product_id = p.product_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY p.product_category_name
ORDER BY avg_delivery_days DESC;


-- Top 5 Categories by Sales (CTE)
WITH category_sales AS (
    SELECT p.product_category_name, SUM(i.price) AS total_sales
    FROM olist_order_items i
    JOIN olist_products p ON i.product_id = p.product_id
    GROUP BY p.product_category_name
)
SELECT TOP 5 *
FROM category_sales
ORDER BY total_sales DESC;


-- Rank Sellers by Total Sales
SELECT seller_id, SUM(price) AS total_sales,
       RANK() OVER (ORDER BY SUM(price) DESC) AS sales_rank
FROM olist_order_items
GROUP BY seller_id;


--  Running Total of Payments per Customer
SELECT o.customer_id, p.order_id, p.payment_value,
       SUM(p.payment_value) OVER (PARTITION BY o.customer_id ORDER BY p.order_id) AS running_total
FROM olist_order_payments p
JOIN olist_orders o ON p.order_id = o.order_id;


-- Average Review Score per Customer vs Global Average
SELECT r.order_id, o.customer_id, r.review_score,
       AVG(r.review_score) OVER (PARTITION BY o.customer_id) AS avg_customer_score,
       AVG(r.review_score) OVER () AS global_avg_score
FROM olist_order_reviews r
JOIN olist_orders o ON r.order_id = o.order_id;


-- Orders per Month
SELECT FORMAT(order_purchase_timestamp,'yyyy-MM') AS purchase_month,
       COUNT(*) AS total_orders
FROM olist_orders
GROUP BY FORMAT(order_purchase_timestamp,'yyyy-MM')
ORDER BY purchase_month;


--  Monthly Revenue (Price + Freight)
SELECT FORMAT(o.order_purchase_timestamp,'yyyy-MM') AS purchase_month,
       SUM(i.price + i.freight_value) AS total_revenue
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY FORMAT(o.order_purchase_timestamp,'yyyy-MM')
ORDER BY purchase_month;


-- Average Order Value
WITH order_totals AS (
  SELECT i.order_id, SUM(i.price + i.freight_value) AS order_total
  FROM olist_order_items i
  GROUP BY i.order_id
)
SELECT AVG(order_total) AS avg_order_value, COUNT(*) AS num_orders
FROM order_totals;


-- Top Categories by Revenue (Translation Included)
SELECT TOP 10 
  COALESCE(t.product_category_name_english, p.product_category_name) AS category,
  SUM(i.price + i.freight_value) AS revenue
FROM olist_order_items i
JOIN olist_products p ON i.product_id = p.product_id
LEFT JOIN olist_product_category_name_translation t 
  ON p.product_category_name = t.product_category_name
GROUP BY COALESCE(t.product_category_name_english, p.product_category_name)
ORDER BY revenue DESC;


-- Seller Ranking by Revenue
SELECT seller_id, total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM (
  SELECT seller_id, SUM(price + freight_value) AS total_revenue
  FROM olist_order_items
  GROUP BY seller_id
) s
ORDER BY total_revenue DESC;


-- Average Delivery Days & Percent Late
SELECT AVG(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days,
       100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END)
            / SUM(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END) AS pct_late_deliveries
FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- Compare Review Score for Late vs On-Time Deliveries
SELECT CASE 
         WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
         WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'OnTime'
         ELSE 'Unknown' END AS delivery_status,
       AVG(r.review_score) AS avg_review_score,
       COUNT(*) AS num_reviews
FROM olist_order_reviews r
JOIN olist_orders o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY CASE 
           WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
           WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'OnTime'
           ELSE 'Unknown' END;


--  Payment Types Summary
SELECT payment_type,
       COUNT(*) AS num_payments,
       SUM(payment_value) AS total_value,
       AVG(payment_value) AS avg_value
FROM olist_order_payments
GROUP BY payment_type
ORDER BY total_value DESC;


--  Average Freight by Price Decile
WITH price_buckets AS (
  SELECT price, freight_value,
         NTILE(10) OVER (ORDER BY price) AS decile
  FROM olist_order_items
)
SELECT decile,
       COUNT(*) AS n_items,
       AVG(price) AS avg_price,
       AVG(freight_value) AS avg_freight
FROM price_buckets
GROUP BY decile
ORDER BY decile;


-- Customer Total Spend & Rank
WITH cust_spend AS (
  SELECT o.customer_id, SUM(p.payment_value) AS total_spent
  FROM olist_order_payments p
  JOIN olist_orders o ON p.order_id = o.order_id
  GROUP BY o.customer_id
)
SELECT customer_id, total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM cust_spend
ORDER BY total_spent DESC;
