select 
group_name,
category_name,
city,
count(product_name) as SKU_qty,
sum(quantity) as stock_qty,
sum(cost_price_amount) as stock_cost
from (
	select *
	from products
	left join inventory
		using(product_id)
	left join product_categories
		using(category_id)
	left join product_groups
		using(group_id)
	left join suppliers
		using(supplier_id)
	) t1
group by group_name, category_name, city
order by group_name,category_name, stock_cost desc



select 
	distinct country,
	count(customer_id)
from customers c 
group by 1
order by 2 desc

select * from customers c --suppliers


select count(*) from sandbox.orders_fact
where created_at = (select max(created_at) from sandbox.orders_fact)

truncate sandbox.orders_fact
truncate sandbox.sales_fact

SELECT 
	inv_prod_id, 
	inv_cost_price, 
	quantity,
	price
FROM 
	(
	(select product_id as inv_prod_id, cost_price as inv_cost_price, quantity from sandbox.inventory_fact
	where product_id in (1, 2, 10)) inv
	left join dw.products_dim pd on inv_prod_id = pd.product_id 
	) t1

select product_id, sum(sales)
from sandbox.sales_fact sf
group by product_id
order by 2 desc 
-- data to daily_inventory_fact