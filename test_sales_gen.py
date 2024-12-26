import pg8000.native
import random
import itertools

conn = pg8000.native.Connection( 
    user="postgres", 
    password="$uperu$er", 
    database="de_catman_proj", 
    host="localhost", 
    port=5432 )
# read all date of year 2016 from calendar 
date_set = conn.run("SELECT date, month FROM dw.calendar_dim where year = 2016")
print('qty days in year = ', len(date_set))

# read all customers ID
customer_ids_set = conn.run("select customer_id from dw.customers_dim")
print(f'Number of Customers:{len(customer_ids_set)}')
#print(f'first customer_id: {customer_ids_set[0][0]}')

# read products
product_ids_set = conn.run("select product_id, price, cost_price from dw.products_dim")
print(f'Number of products:{len(product_ids_set)}')
#print(f'product_id: {product_ids_set[0][0]}')
#print(f'price: {product_ids_set[0][1]}')
#print(f'cost_price: {product_ids_set[0][2]}')

# read inventory
inventory_set = conn.run("select product_id from sandbox.inventory_fact where quantity > 0")
print(f'Number of products on stock: {len(inventory_set)}')
inventory_set = list(itertools.chain.from_iterable(inventory_set)) #change to flat_list

day = 0
order_qty_day_min = order_qty_day_start = 160     # min order qty per day, start for 2016                   
factor_orders_day = 0.05    # increase factor 5% pro month
month = 1
month_act = 0

for day in range(1):#(len(date_set)):
    print(f"Date: {date_set[day][0]}, Month: {date_set[day][1]}")      # info
   
    # calculation of min limit of the qty of order monthly, qty orders increases monthly for 5%.
    month = date_set[day][1] # number of month
    if month != month_act:
        month_act = month
        order_qty_day_min = order_qty_day_min + round(order_qty_day_start * ((month_act - 1) * factor_orders_day))
    
    #random qty orders per each day-  diff between min and max = 20%.
    order_qty = random.randint(order_qty_day_min, round(order_qty_day_min * 1.2)) 
    print('qty orders per day = ', order_qty) #info
    
    #generating a random sequence of indexes for sampling from a customer_ids_set 
    customer_ids = random.sample(range(1, len(customer_ids_set) + 1), order_qty) 
    print('customer ids: ', customer_ids)
    print('qty customers per day = ', len(customer_ids))
 
    #generate order set for each customer
    for customer in (customer_ids):
        print(f'Customer_id: {customer_ids_set[customer-1][0]}')
        sku_qty = random.randint(1, 5) #generate qty of SKU in order
        sku_order = random.sample(range(1, len(product_ids_set)), sku_qty) # generate number of product_ids for each order
        print(f'there are {len(sku_order)} SKUs in order')
        shipment_set = [] #list product_id to be shipment to customer
        backorder_set = [] #list product_id to be noted in backorder
        
        #checking stock availability
        for sku in sku_order:
            print(f'product_id: {product_ids_set[sku-1][0]}')
            if product_ids_set[sku-1][0] in inventory_set:
                shipment_set.append(product_ids_set[sku-1][0])
            else:
                backorder_set.append(product_ids_set[sku-1][0])
        print(f'to schip: {shipment_set}')       
        shipment_set_str = ', '.join(map(str, shipment_set)) # Преобразование списка в строку с форматированием
        
        # читаю со склада себестоимость cost_price, доступный остаток quantity    
        sql_query = f"SELECT product_id, cost_price, quantity FROM sandbox.inventory_fact where product_id in ({shipment_set_str})"
        # getting list of list from inventory
        sales_set = conn.run(sql_query)
        print(sales_set)
        
        # формирование записей в таблицу sandbox.backorder_fact если backorder_set не пустой
        # формирование записей в таблицу sandbox.sales_fact
        # изменение записей в таблице sandbox.inventory_fact
# снимок таблицы sandbox.inventory_fact в таблицу sandbox.daily_inventory_fact


conn.close