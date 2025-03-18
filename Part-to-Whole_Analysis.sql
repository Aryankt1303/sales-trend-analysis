use datawarehouseanalytics;

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




















