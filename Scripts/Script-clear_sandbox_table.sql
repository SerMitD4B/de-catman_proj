truncate sandbox.backorders_fact; 
truncate sandbox.daily_inventory_fact; 
truncate sandbox.inventory_fact; 
truncate sandbox.orders_fact;
truncate sandbox.sales_fact;
truncate sandbox.purchase_fact;

insert into sandbox.inventory_fact (inventory_id, quantity, cost_price,created_at, product_id)
select inventory_id, quantity, cost_price,created_at, product_id from dw.inventory_fact 

select * from sandbox.orders_fact

select count(*) from sandbox.sales_fact


select count(*)
from sandbox.inventory_fact if2 
where quantity > 0

select * 
from (
select extract('month'from order_date) as month, sum(sales) as Total_sales, sum(quantity) as sales_qty 
from sandbox.sales_fact
group by month) t1
left join ( 
	select extract('month'from date_backorder) as month, sum(quantity) as backorder_qty 
	from sandbox.backorders_fact bf 
	group by month
	) t2
using(month)
order by month




select product_id, sum(quantity)
from sandbox.backorders_fact bf
group by 1
order by 2 desc 

select distinct status from sandbox.purchase_fact pf 

select count(customer_id) from dw.customers_dim
