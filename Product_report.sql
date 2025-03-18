use datawarehouseanalytics;

/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================

CREATE VIEW datawarehouseanalytics.cust_analysis AS
WITH cust_detail AS (
    SELECT
        s.product_key,
        s.order_number,
        s.order_date,
        c.customer_id,
        s.sales_amount,
        s.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS Full_name,
        ROUND(DATEDIFF(CURRENT_DATE(), c.birthdate) / 365) AS Age
    FROM
        gold_dim_customers c
    INNER JOIN 
        gold_fact_sales s
        ON c.customer_key = s.customer_key 
    WHERE ROUND(DATEDIFF(CURRENT_DATE(), c.birthdate) / 365) IS NOT NULL
),
aggregate_table AS (
    SELECT 
        customer_key,
        customer_id,
        Full_name,
        Age,
        ROUND(DATEDIFF(MAX(order_date), MIN(order_date)) / 30) AS Lifespan,
        COUNT(DISTINCT order_number) AS Total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        MAX(order_date) AS last_order
    FROM 
        cust_detail
    GROUP BY 
        customer_id,
        customer_key,
        Full_name,
        Age
)
SELECT 
    customer_key,
    customer_id,
    Full_name,
    Age,
    CASE 
        WHEN Age <= 20 THEN 'Below 20'
        WHEN Age BETWEEN 21 AND 50 THEN 'Below 50'
        ELSE 'Above 50'
    END AS Age_group,
    Total_orders,
    total_sales,
    total_quantity,
    last_order,
    ROUND(DATEDIFF(CURRENT_DATE(), last_order) / 30) AS recency,
    Lifespan,
    CASE 
        WHEN total_sales > 5000 AND Lifespan > 12 THEN 'VIP'
        WHEN total_sales <= 5000 AND Lifespan > 12 THEN 'Regular'
        ELSE 'New'
    END AS status,
    ROUND(total_sales / Total_orders, 2) AS avg_order_value,
    CASE 
        WHEN Lifespan = 0 THEN total_sales
        ELSE ROUND(total_sales / Lifespan, 2)
    END AS Avg_monthly_spend
FROM 
    aggregate_table;





















