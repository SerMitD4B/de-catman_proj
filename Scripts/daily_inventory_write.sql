insert into daily_inventory (product_id, quantity, cost_price_amount)
select product_id, quantity, cost_price_amount from inventory

select 
	distinct date_trunc('day',inventory_date),
	count(*)
from daily_inventory di 
group by 1