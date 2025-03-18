use datawarehouseanalytics;

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


















