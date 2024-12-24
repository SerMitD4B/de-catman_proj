select * from dw.products_dim pd 
limit 10

select * from public_old.products p

update dw.products_dim 
set cost_price = public_old.products.cost_price
from public_old.products
where dw.products_dim.product_id = public_old.products.product_id
