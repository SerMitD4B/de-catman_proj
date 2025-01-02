import pg8000.native
import random
import itertools

conn = pg8000.native.Connection( 
    user="postgres", 
    password="$uperu$er", 
    database="de_catman_proj", 
    host="localhost", 
    port=5432 )

inventory_set = conn.run("select product_id from sandbox.inventory_fact where quantity > 0")
print(f'Number of products on stock: {len(inventory_set)}')
print(type(inventory_set))
print(inventory_set)

# Преобразование с помощью itertools.chain 
flat_list = list(itertools.chain.from_iterable(inventory_set))

print(type(flat_list))
print(flat_list)

if 3 in flat_list:
    print('ok')
else:
    print('not ok')

conn.close