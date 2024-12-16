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