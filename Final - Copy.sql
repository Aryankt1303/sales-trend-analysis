use datawarehouseanalytics;

/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/
select
year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as customer,
sum(quantity) as Total_quantity
from gold_fact_sales gfs 
where order_date <> ""
group by month(order_date),year(order_date) 
order by year(order_date),month(order_date)
;

/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/

select 
order_month, sales, 
sum(sales) over (order by order_month) as cumm_sales
from
(
select 
month(order_date) as order_month, 
sum(sales_amount) as sales 
from gold_fact_sales
where month(order_date) is not null
group by month(order_date)
) subquery
;

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

/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/

select 
p.category,
sum(s.sales_amount) as Total_sales,
concat((sum(s.sales_amount)/sum(sum(s.sales_amount)) over())*100,'%') as percentage
from
gold_dim_products P
inner join gold_fact_sales s
on p.product_key = s.product_key 
group by p.category 
order by percentage desc
;


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

with cost_seg as
(select 
product_key,
cost,
case 
	when cost between 0 and 100 then "Below 100"
	when cost between 100 and 500 then "Below 500"
	when cost between 5000 and 1000 then "Below 1000"
	else "Above 1000"
end as Range_cost
from 
gold_dim_products)
select
Range_cost, count(*) as total_prod
from 
cost_seg
group by Range_cost
order by count(*) desc
;


/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
-- Which categories contribute the most to overall sales?

with cust_detail as 
(SELECT 
c.customer_key,
SUM(s.sales_amount) AS Total_spending,
MIN(s.order_date) AS min_order_date,
MAX(s.order_date) AS max_order_date,
TIMESTAMPDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)) AS lifespan
FROM 
gold_dim_customers c
INNER JOIN 
gold_fact_sales s
ON 
c.customer_key = s.customer_key 
GROUP BY 
c.customer_key
ORDER BY 
c.customer_key)
select 
case 
	when total_spending > 5000 and lifespan > 12 then 'VIP'
	when total_spending < 5000 and lifespan > 12 then 'Regula'
	else 'New'
end status,
count(*)
from 
cust_detail
group by status
;

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





















