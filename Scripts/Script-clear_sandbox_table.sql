truncate sandbox.backorders_fact; 
truncate sandbox.daily_inventory_fact; 
truncate sandbox.inventory_fact; 
truncate sandbox.orders_fact;
truncate sandbox.sales_fact;
truncate sandbox.purchase_fact;

insert into sandbox.inventory_fact (inventory_id, quantity, cost_price,created_at, product_id)
select inventory_id, quantity, cost_price,created_at, product_id from dw.inventory_fact 



