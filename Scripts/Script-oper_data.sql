--to get qty of customers per country
select * 
from (
select
		geo_id,
		count(customer_id)
	from dw.customers_dim 
	group by 1 ) t1
left join dw.geo_dim gd 
using(geo_id)
order by 2 desc;

-- get stock cost per category
select 
	group_name,
--	category_name,
--	country,
	count(product_id) as SKU_qty,
	sum(quantity) as stock_qty,
	sum(cost_price) as stock_cost
from (
	select *
	from sandbox.inventory_fact if2 
	left join (select product_id, category_id, supplier_id from dw.products_dim) pd
		using(product_id)
	left join dw.category_dim cd 
		using(category_id)
	left join dw.group_dim gd 
		using(group_id)
	left join dw.suppliers_dim sd
		using(supplier_id)
	left join dw.geo_dim geod 
		using(geo_id)
	) t1
group by group_name, category_name--, country
order by stock_cost desc--group_name,category_name--, stock_cost desc

-- get stock cost per day for 30 days period
select 
	inventory_date,
	sum(cost_price)
from sandbox.daily_inventory_fact
group by inventory_date 
order by inventory_date desc
limit 60

-- goods incomming forecast per day
select 
	*,
	sum(cost_incomming) over(partition by date_trunc('month', for_date)) as total_month,
	round(100 * cost_incomming / sum(cost_incomming) over(partition by date_trunc('month', for_date)),2) as share_incomming
from (	
	select 
		date(date_trunc('day', delivery_date)) as for_date, 
		sum(order_cost) as cost_incomming--,
	from sandbox.purchase_fact
	where status = 'pending'
	group by 1
	) t1
group by for_date, cost_incomming
order by for_date

-- get sales
select 
	extract ('year' from order_date) as year,
	extract ('month' from order_date)as month,
	round(sum(sales),0) as sales,
	round(sum(cogs),0) as cogs,
	round(sum(profit),0) as profit
from sandbox.sales_fact sf
group by 1,2

select count(*)
from sandbox.sales_fact sf

select count(*)
from sandbox.orders_fact of2 

-- get sales + backorder qty
select * 
from (
select extract('year' from order_date) as year, extract('month'from order_date) as month, sum(sales) as Total_sales, sum(quantity) as sales_qty 
from sandbox.sales_fact
group by  year, month) t1
left join ( 
	select extract('year' from date_backorder) as year, extract('month'from date_backorder) as month, sum(quantity) as backorder_qty 
	from sandbox.backorders_fact bf 
	group by year, month
	) t2
on t2.month = t1.month and t2.year = t1.year
order by t1.year, t1.month
