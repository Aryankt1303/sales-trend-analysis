use datawarehouseanalytics;

/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

WITH product_sales AS (
    SELECT
        YEAR(s.order_date) AS Year_sales,
        p.product_name,
        SUM(s.sales_amount) AS total_sales
    FROM gold_fact_sales s
    INNER JOIN gold_dim_products p
        ON s.product_key = p.product_key 
    WHERE YEAR(s.order_date) IS NOT NULL
    GROUP BY YEAR(s.order_date), p.product_name
)
SELECT 
Year_sales, 
product_name, 
total_sales,
sum(total_sales) OVER (PARTITION BY product_name) AS cummalative_sales,
(total_sales/sum(total_sales) OVER (PARTITION BY product_name))*100 as Sales_percent
FROM product_sales
ORDER BY product_name, Year_sales;















