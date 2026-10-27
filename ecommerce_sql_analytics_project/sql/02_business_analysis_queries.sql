-- E-commerce SQL Analytics | SQLite 3.x
-- Revenue analyses count Delivered orders only.
-- Net sales = quantity * charged unit price * (1 - discount_pct).

-- Q1: Business overview
SELECT COUNT(DISTINCT o.order_id) AS delivered_orders,
       COUNT(DISTINCT o.customer_id) AS customers,
       ROUND(SUM(i.quantity*i.unit_price*(1-i.discount_pct)),2) AS net_sales
FROM orders o JOIN order_items i ON i.order_id=o.order_id
WHERE o.order_status='Delivered';

-- Q2: Monthly net sales and month-over-month growth (CTE + LAG)
WITH monthly AS (
 SELECT strftime('%Y-%m',o.order_date) AS month,
        SUM(i.quantity*i.unit_price*(1-i.discount_pct)) AS net_sales
 FROM orders o JOIN order_items i ON i.order_id=o.order_id
 WHERE o.order_status='Delivered'
 GROUP BY strftime('%Y-%m',o.order_date)
), prev AS (
 SELECT month, net_sales, LAG(net_sales) OVER(ORDER BY month) AS prior_month
 FROM monthly
)
SELECT month, ROUND(net_sales,2) AS net_sales, ROUND(prior_month,2) AS prior_month,
 ROUND(100.0*(net_sales-prior_month)/NULLIF(prior_month,0),2) AS mom_growth_pct
FROM prev ORDER BY month;

-- Q3: Top 10 products by net sales
SELECT p.product_name,p.category,
 ROUND(SUM(i.quantity*i.unit_price*(1-i.discount_pct)),2) AS net_sales,
 SUM(i.quantity) AS units_sold
FROM orders o JOIN order_items i ON i.order_id=o.order_id
JOIN products p ON p.product_id=i.product_id
WHERE o.order_status='Delivered'
GROUP BY p.product_id,p.product_name,p.category
ORDER BY net_sales DESC LIMIT 10;

-- Q4: Category profitability (estimated; excludes overhead, shipping and tax)
SELECT p.category,
 ROUND(SUM(i.quantity*i.unit_price*(1-i.discount_pct)),2) AS net_sales,
 ROUND(SUM(i.quantity*p.unit_cost),2) AS estimated_cost,
 ROUND(SUM(i.quantity*(i.unit_price*(1-i.discount_pct)-p.unit_cost)),2) AS estimated_profit,
 ROUND(100.0*SUM(i.quantity*(i.unit_price*(1-i.discount_pct)-p.unit_cost)) /
 NULLIF(SUM(i.quantity*i.unit_price*(1-i.discount_pct)),0),2) AS estimated_margin_pct
FROM orders o JOIN order_items i ON i.order_id=o.order_id
JOIN products p ON p.product_id=i.product_id
WHERE o.order_status='Delivered'
GROUP BY p.category ORDER BY estimated_profit DESC;

-- Q5: Highest-value customers by delivered sales
SELECT c.customer_id,c.customer_name,c.segment,c.region,
 COUNT(DISTINCT o.order_id) AS delivered_orders,
 ROUND(SUM(i.quantity*i.unit_price*(1-i.discount_pct)),2) AS customer_net_sales
FROM customers c JOIN orders o ON o.customer_id=c.customer_id
JOIN order_items i ON i.order_id=o.order_id
WHERE o.order_status='Delivered'
GROUP BY c.customer_id,c.customer_name,c.segment,c.region
ORDER BY customer_net_sales DESC LIMIT 20;

-- Q6: Repeat purchase rate
WITH customer_orders AS (
 SELECT customer_id,COUNT(*) AS delivered_orders
 FROM orders WHERE order_status='Delivered' GROUP BY customer_id
)
SELECT COUNT(*) AS purchasing_customers,
 SUM(CASE WHEN delivered_orders>=2 THEN 1 ELSE 0 END) AS repeat_customers,
 ROUND(100.0*SUM(CASE WHEN delivered_orders>=2 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),2) AS repeat_rate_pct
FROM customer_orders;

-- Q7: Customers with no delivered order in the last 90 days of the dataset
WITH end_date AS (SELECT MAX(order_date) AS max_date FROM orders),
last_order AS (
 SELECT customer_id,MAX(order_date) AS last_delivered_date FROM orders
 WHERE order_status='Delivered' GROUP BY customer_id
)
SELECT c.customer_id,c.customer_name,c.region,l.last_delivered_date,
 CAST(julianday((SELECT max_date FROM end_date))-julianday(l.last_delivered_date) AS INTEGER) AS days_inactive
FROM customers c LEFT JOIN last_order l ON l.customer_id=c.customer_id
WHERE l.last_delivered_date IS NULL OR
 julianday((SELECT max_date FROM end_date))-julianday(l.last_delivered_date)>90
ORDER BY days_inactive DESC;

-- Q8: Revenue share and ranking by region (window functions)
WITH region_sales AS (
 SELECT c.region,SUM(i.quantity*i.unit_price*(1-i.discount_pct)) AS net_sales
 FROM customers c JOIN orders o ON o.customer_id=c.customer_id
 JOIN order_items i ON i.order_id=o.order_id
 WHERE o.order_status='Delivered' GROUP BY c.region
)
SELECT region,ROUND(net_sales,2) AS net_sales,
 ROUND(100.0*net_sales/SUM(net_sales) OVER(),2) AS revenue_share_pct,
 DENSE_RANK() OVER(ORDER BY net_sales DESC) AS region_rank
FROM region_sales ORDER BY region_rank;

-- Q9: Monthly cancellation and return rates
SELECT strftime('%Y-%m',order_date) AS month,COUNT(*) AS total_orders,
 SUM(CASE WHEN order_status='Cancelled' THEN 1 ELSE 0 END) AS cancelled,
 SUM(CASE WHEN order_status='Returned' THEN 1 ELSE 0 END) AS returned,
 ROUND(100.0*SUM(CASE WHEN order_status='Cancelled' THEN 1 ELSE 0 END)/COUNT(*),2) AS cancellation_pct,
 ROUND(100.0*SUM(CASE WHEN order_status='Returned' THEN 1 ELSE 0 END)/COUNT(*),2) AS return_pct
FROM orders GROUP BY strftime('%Y-%m',order_date) ORDER BY month;

-- Q10: Top three products within each category (ROW_NUMBER)
WITH product_sales AS (
 SELECT p.category,p.product_name,SUM(i.quantity*i.unit_price*(1-i.discount_pct)) AS net_sales
 FROM products p JOIN order_items i ON i.product_id=p.product_id
 JOIN orders o ON o.order_id=i.order_id WHERE o.order_status='Delivered'
 GROUP BY p.category,p.product_id,p.product_name
), ranked AS (
 SELECT *,ROW_NUMBER() OVER(PARTITION BY category ORDER BY net_sales DESC) AS product_rank
 FROM product_sales
)
SELECT category,product_name,ROUND(net_sales,2) AS net_sales,product_rank
FROM ranked WHERE product_rank<=3 ORDER BY category,product_rank;

-- Q11: Average order value, calculated from one total per order
WITH order_totals AS (
 SELECT o.order_id,SUM(i.quantity*i.unit_price*(1-i.discount_pct)) AS order_sales
 FROM orders o JOIN order_items i ON i.order_id=o.order_id
 WHERE o.order_status='Delivered' GROUP BY o.order_id
)
SELECT COUNT(*) AS delivered_orders,ROUND(AVG(order_sales),2) AS average_order_value
FROM order_totals;

-- Q12: Payment method mix
SELECT payment_method,COUNT(*) AS delivered_orders,
 ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),2) AS order_share_pct
FROM orders WHERE order_status='Delivered'
GROUP BY payment_method ORDER BY delivered_orders DESC;

-- Extension challenges:
-- 1. RFM segmentation using Recency, Frequency, Monetary value.
-- 2. Monthly customer cohorts and retention.
-- 3. High-sales products with below-average estimated margins.
-- 4. Cancellation rate by customer segment and region.
