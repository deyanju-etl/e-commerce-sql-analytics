-- SQL Queries for Olist E-Commerce Data

-- View First 10 Customers
SELECT TOP 10 *
FROM olist_customers;


--  Get all Orders with Delivered Status
SELECT *
FROM olist_orders
WHERE order_status = 'delivered';


-- Top 5 Most Expensive Orders (freight + price)
SELECT TOP 5 order_id, price, freight_value
FROM olist_order_items
ORDER BY (price + freight_value) DESC;


-- Total Number of Customers per State
SELECT customer_state, COUNT(*) AS number_of_customers
FROM olist_customers
GROUP BY customer_state
ORDER BY number_of_customers DESC;


-- Average Order Value per Payment Type
SELECT payment_type, AVG(payment_value) AS avg_payment_value
FROM olist_order_payments
GROUP BY payment_type
ORDER BY avg_payment_value DESC;


-- Sellers with More Than 50 Orders
SELECT seller_id, COUNT(order_id) AS total_orders
FROM olist_order_items
GROUP BY seller_id
HAVING COUNT(order_id) > 50
ORDER BY total_orders DESC;


-- Join Customers with their Orders
SELECT c.customer_id, c.customer_state, o.order_id, o.order_status
FROM olist_customers c
INNER JOIN olist_orders o
    ON c.customer_id = o.customer_id;


-- Left Join to See Customers with or without Orders
SELECT c.customer_id, o.order_id
FROM olist_customers c
LEFT JOIN olist_orders o
    ON c.customer_id = o.customer_id
WHERE order_id IS NOT NULL;
