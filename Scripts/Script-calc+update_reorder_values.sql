-- get data to calculate reorder_qty
with calc_reorder_values as (
	select 
		recalc_order_qty.product_id,
		calc_reorder_level,
		calc_reorder_quantity--,
	--	(calc_reorder_level - reorder_level) * cost_price as diff_level,
	--	(calc_reorder_quantity - reorder_quantity) * cost_price as diff_qty
	from(
		select 
			pd.product_id,
			pd.cost_price,
			reorder_level,
			reorder_quantity,
			supplier_id,
			lead_time,
			delay_time,
			delivery_cycle,
			sold_qty,
			sales_day,
			coalesce(qty_days_OOS,0) as qty_days_OOS,
			(select count(*) from dw.calendar_dim cd where date between '2016-06-01' and '2017-05-31') - coalesce(qty_days_OOS,0) as qty_days_OS,
			round((sold_qty::numeric / ((select count(*) from dw.calendar_dim cd where date between '2016-06-01' and '2017-05-31') - coalesce(qty_days_OOS,0))),2) as sold_per_day,
			round((lead_time + delay_time) * (sold_qty::numeric / ((select count(*) from dw.calendar_dim cd where date between '2016-06-01' and '2017-05-31') - coalesce(qty_days_OOS,0))),0) as calc_reorder_level,
			round(lead_time * (sold_qty::numeric / ((select count(*) from dw.calendar_dim cd where date between '2016-06-01' and '2017-05-31') - coalesce(qty_days_OOS,0))),0) as calc_reorder_quantity
		from dw.products_dim pd 
		right join (
			select product_id, 
			sum(quantity) as sold_qty,
			count(distinct order_date) as sales_day
			from sandbox.sales_fact 
			where order_date in (select date from dw.calendar_dim cd where date between '2016-06-01' and '2017-05-31')
			group by product_id) sf
			on pd.product_id  = sf.product_id
		left join (
			select 
				product_id,
				count(inventory_date) AS qty_days_OOS
			from sandbox.daily_inventory_fact  
			where inventory_date in (select date from dw.calendar_dim cd where date between '2016-06-01' and '2017-05-31')
				and quantity = 0
			group by product_id
			) dif
			on pd.product_id  = dif.product_id
		left join dw.suppliers_dim sd 
			using(supplier_id)
		) recalc_order_qty	
	)
update dw.products_dim 
set
	reorder_level = calc_reorder_values.calc_reorder_level,
	reorder_quantity = calc_reorder_values.calc_reorder_quantity
from calc_reorder_values
where dw.products_dim.product_id = calc_reorder_values.product_id 
