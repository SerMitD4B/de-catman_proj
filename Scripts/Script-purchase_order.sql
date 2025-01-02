insert into sandbox.purchase_fact (order_date, delivery_date, supplier_id, product_id, quantity, cost_price, status)
select
	TO_DATE('2016-01-01', 'YYYY-MM-DD') as order_date, -- здесь current_date = передать параметром дату из генератора продаж
	(TO_TIMESTAMP('2016-01-01', 'YYYY-MM-DD') + (lead_time * INTERVAL '1 day'))::date as delivery_date,
	supplier_id,
	product_id,
	reorder_quantity as quantity,
	round(price * reorder_quantity, 2) as cost_price,
	'pending' as status
from (
	select 
		pd.product_id, 
		price, 
		reorder_level, 
		reorder_quantity, 
		available_qty,
		case
			when pending_qty is null then 0
			else pending_qty
		end as pending_qty,
		lead_time,
		pd.supplier_id
	from (
		select * 
		from dw.products_dim 
		where reorder_level > 0
		) pd
		left join ( --actual available stock qty
			select 
				product_id, 
				quantity as available_qty 
			from sandbox.inventory_fact
			) if2 
			on if2.product_id = pd.product_id
		left join ( --goods are on the way from suppliers
			select 
				product_id, 
				sum(quantity) as pending_qty
			from sandbox.purchase_fact
			where status != 'completed'
			group by product_id
			order by product_id
			) purch_orders
			on if2.product_id = purch_orders.product_id
		left join (
			select supplier_id, lead_time
			from dw.suppliers_dim
			) suppl_delivery_time
			on suppl_delivery_time.supplier_id = pd.supplier_id
	order by pd.supplier_id, product_id
) as set_to_purchase
where reorder_level > (available_qty + pending_qty)

select supplier_id, round(sum(cost_price),0) from sandbox.purchase_fact
where status != 'completed'
group by supplier_id
order by sum(cost_price) desc

select distinct status, sum(cost_price) 
from sandbox.purchase_fact
group by 1

/*
insert into sandbox.purchase_fact (order_date, delivery_date, supplier_id, product_id, quantity, cost_price)
values(current_date, (current_date + 28), 5, 44, 94, 32.04)
*/
