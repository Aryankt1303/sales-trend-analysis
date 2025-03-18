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























