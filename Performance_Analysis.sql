use datawarehouseanalytics;

/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
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
    ROUND(AVG(total_sales) OVER (PARTITION BY product_name)) AS Average_sales,
    (total_sales - ROUND(AVG(total_sales) OVER (PARTITION BY product_name))) AS Avg_diff,
    CASE 
        WHEN total_sales - ROUND(AVG(total_sales) OVER (PARTITION BY product_name)) < 0 THEN 'Below Avg'
        WHEN total_sales - ROUND(AVG(total_sales) OVER (PARTITION BY product_name)) > 0 THEN 'Above Avg'
        ELSE 'Avg'
    END AS change_diff,
    total_sales - lag(total_sales) over (partition by product_name order by Year_sales) as Prev_year_value,
    CASE 
        WHEN total_sales - lag(total_sales) over (partition by product_name order by Year_sales) < 0 THEN 'Decrease'
        WHEN total_sales - lag(total_sales) over (partition by product_name order by Year_sales) > 0 THEN 'Increase'
        ELSE 'Non change'
    END AS Prev_year_change
FROM product_sales
ORDER BY product_name, Year_sales;

















