select * from dw.products_dim pd 
limit 10

select * from public_old.products p

update dw.products_dim 
set cost_price = public_old.products.cost_price
from public_old.products
where dw.products_dim.product_id = public_old.products.product_id


select * from dw.calendar_dim cd 
where week = 53

select * from dw.customers_dim cd 
limit 100

SELECT *
FROM dw.inventory_fact;

insert into sandbox.inventory_fact (inventory_id, quantity, cost_price, created_at, product_id)
SELECT inventory_id, quantity, cost_price, created_at, product_id
FROM dw.inventory_fact;


SELECT inventory_id, quantity, cost_price, created_at, product_id
FROM sandbox.inventory_fact;

select product_id from sandbox.inventory_fact where quantity > 0

SELECT product_id, cost_price, quantity FROM sandbox.inventory_fact where product_id in (151)


select count(*) from dw.products_dim pd 
limit 100