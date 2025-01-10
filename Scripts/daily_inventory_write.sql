insert into sandbox.daily_inventory_fact (product_id, quantity, cost_price, inventory_date)
select product_id, quantity, cost_price, '2016-01-01' from sandbox.inventory_fact 

select count(*) from sandbox.daily_inventory_fact dif 

-- проверяем корректность обновления данных 
select *
from(
	select 
		product_id,
		sum(quantity) as daily_qty,
		sum(cost_price) as daily_cost
	from sandbox.daily_inventory_fact di 
	group by 1
	) daily_stock
	left join (
		select 
			product_id,
			sum(quantity) as stock_qty,
			sum(cost_price) as stock_cost
		from sandbox.inventory_fact 
		group by 1
		) if2 
		on daily_stock.product_id = if2.product_id
order by 1

SELECT purchase_id, order_id, order_date, delivery_date, supplier_id, product_id, quantity, cost_price, status, created_at
FROM sandbox.purchase_fact;

select product_id, product_name, reorder_level, reorder_quantity, supplier_id from dw.products_dim pd 
left join sandbox.inventory_fact if2 using (product_id)

select * 
from(
select extract('month' from inventory_date) as month_year, 
round(avg(cost_price),2) as avg_stock
from sandbox.daily_inventory_fact
group by 1
order by 1
) t1
left join (
	select 
		extract('month' from order_date) as month_year, 
		sum(cogs) as sum_cogs, 
		sum(profit) as sum_profit
--		round(100 * sum(profit) / (sum(cogs) + sum(profit)),2) as ROS_percent
	from sandbox.sales_fact sf
	group by 1) t2
	on t1.month_year = t2.month_year

select   -- растет себестоимость
	product_id,
	extract('month' from order_date) as month_year, 
	sum(quantity) as sum_qty,
	sum(cogs) as sum_cogs,
	round(sum(cogs) / sum(quantity),2) as cogs_1pcs,
	sum(profit) as sum_profit,
	round(100 * sum(profit) / (sum(cogs) + sum(profit)),2) as ROS_percent
from sandbox.sales_fact sf
where product_id in (1,2,3,4,5)
group by 1,2
order by 1,2

select  -- стабильная себестоимость
	product_id,
	extract('month' from order_date) as month_year,
	sum(order_quantity) as sum_qty,
	sum(order_cost) as sum_cogs,
	round(sum(order_cost) / sum(order_quantity),2) as cogs_1pcs
from sandbox.purchase_fact
where product_id in (1,2,3,4,5)
group by 1,2
order by 1,2

select * from sandbox.purchase_fact
where product_id in (1)
order by  order_date 
limit 50

select
	inv_month,
	avg_inv_cost,
	sum_cogs_sales,
	sum_profit,
	round(100 * sum_profit / avg_inv_cost, 2) as ROI,
	round(avg_inv_cost / sum_cogs_sales, 1) as inv_turnover_month,
	sum_back_qty
from (select
	extract('month' from inv_day) as inv_month,
	round(avg(sum_cogs),2) as avg_inv_cost
from (
	select
		date_trunc('day',inventory_date) as inv_day,
		sum(cost_price) as sum_cogs
	from sandbox.daily_inventory_fact
	group by 1
	) as inv
group by 1) as inv2
left join (
	select 
		extract('month' from order_date) as sales_month, 
		sum(cogs) as sum_cogs_sales, 
		sum(profit) as sum_profit
	from sandbox.sales_fact sf
	group by 1) as sales
	on inv2.inv_month = sales.sales_month
left join (
	select
		extract('month' from date_backorder) as backorder_month,
		sum(quantity) as sum_back_qty
	from sandbox.backorders_fact
	group by 1) as backorder_fact
	on inv2.inv_month = backorder_fact.backorder_month	
	
select distinct inventory_date, quantity --count(*)
from sandbox.daily_inventory_fact
where product_id = 1
--group by 1
order by 1


select distinct date_trunc('month', order_date), count(*) / 30
from orders_fact of2 
group by 1
order by 1

select *
from dw.category_dim cd 
order by 1

select 
	distinct customer_id, 
	count(distinct order_id)
from sandbox.sales_fact
group by 1
order by 2 desc 

SELECT inv_prod_id, inv_cost_price, quantity, price, cost_price
                            FROM (
                                  (select product_id as inv_prod_id, cost_price as inv_cost_price, quantity from sandbox.inventory_fact
	                               where product_id in (1,2,3,4,5)) inv
	                            left join dw.products_dim pd on inv_prod_id = pd.product_id 
	                            ) t1


