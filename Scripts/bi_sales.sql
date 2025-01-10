
create schema bi_sales;

--creat the table bi_sales.dim_calendar
create table bi_sales.dim_calendar as
select * from dw.calendar_dim cd 

--creat the table bi_sales.dim_product
create table bi_sales.dim_products as
select
	product_id,
	product_name,
	price,
	category_name,
	group_name,
	supplier_name,
	country
from (
	select * from dw.products_dim pd 
	left join dw.suppliers_dim sd 
	using(supplier_id)
	left join dw.geo_dim gd 
	using (geo_id)
	left join dw.category_dim cd 
	using(category_id)
	left join dw.group_dim gd2 
	using(group_id)
) t1
order by 1

--creat the table bi_sales.dim_customer
create table bi_sales.dim_customers as
select 
	customer_id,
	customer_name,
	country
from (
	select * 
	from dw.customers_dim cd
	left join dw.geo_dim gd 
	using(geo_id)
	)t2
	
create table bi_sales.fact_sales as
select 
	sales_id,
	order_id,
	order_date,
	product_id,
	quantity,
	sales,
	cogs,
	profit,
	customer_id
from sandbox.sales_fact sf 

ALTER TABLE bi_sales.fact_sales 
ADD CONSTRAINT fact_sales_pk PRIMARY KEY (sales_id)

alter table bi_sales.dim_customers 
add constraint dim_customer_pk primary key (customer_id)

alter table bi_sales.dim_products 
add constraint dim_product_pk primary key (product_id)

ALTER TABLE bi_sales.fact_sales 
ADD CONSTRAINT fact_customer_fk foreign KEY (customer_id) references bi_sales.dim_customers

alter table bi_sales.fact_sales 
add constraint fact_product_fk foreign key (product_id) references bi_sales.dim_products

SELECT pg_size_pretty(pg_database_size('de_catman_proj'))


select 
	customer_country,
	country as made_in,
	sum(sum(sales)) over(partition by customer_country) as revenue_customer_country,
	sum(sales) as revenue_per_origin,
	round(100 * sum(sales) / sum(sum(sales)) over(partition by customer_country order by customer_country), 2) as share_in_group
from (	
	select *
	from bi_sales.fact_sales fs2 
	left join bi_sales.dim_products dp 
	using(product_id)
	left join (
		select customer_id, customer_name, country as customer_country 
		from bi_sales.dim_customers dc) as customer_set 
	using(customer_id)) d_set
group by 1, 2
order by 3 desc, 4 desc



