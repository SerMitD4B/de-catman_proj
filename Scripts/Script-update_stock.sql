WITH updated_stock AS (
	select 
		purchase_id,
		purch_fact.product_id,
		purch_fact.quantity + inv_fact.quantity as new_quantity_stock, 
		purch_fact.cost_price + inv_fact.cost_price as new_cost_stock
	from (
		select purchase_id, product_id, quantity, cost_price, delivery_date, status
		from sandbox.purchase_fact
		where status != 'completed'
		and delivery_date = '2016-02-15'
		) purch_fact
		left join (
			select product_id, quantity, cost_price
			from sandbox.inventory_fact
		) inv_fact
		on purch_fact.product_id = inv_fact.product_id
	)
UPDATE sandbox.inventory_fact 
SET 
	quantity = updated_stock.new_quantity_stock, 
	cost_price = updated_stock.new_cost_stock 
FROM sandbox.inventory_fact 
WHERE inventory_fact.product_id = updated_stock.product_id;

WITH update_status AS (
	select purchase_id, product_id, quantity, cost_price, delivery_date, status
	from sandbox.purchase_fact
	where status != 'completed'
	and delivery_date = '2016-02-15'
	)

update sandbox.purchase_fact
set
	status = 'completed'
from sandbox.purchase_fact
where sandbox.purchase_fact.purchase_id = update_status.purchase_id;