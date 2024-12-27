import pg8000.native
import random
import itertools
import datetime

conn = pg8000.native.Connection( 
    user="postgres", 
    password="$uperu$er", 
    database="de_catman_proj", 
    host="localhost", 
    port=5432 )
# read all date of year 2016 from calendar 
date_set = conn.run("SELECT date, month FROM dw.calendar_dim where year = 2016")
print('qty days in year = ', len(date_set))
expenses = 3 # additional expenses pro order in 2016

# read all customers ID
customer_ids_set = conn.run("select customer_id from dw.customers_dim")
print(f'Number of Customers:{len(customer_ids_set)}')

# read products
product_ids_set = conn.run("select product_id, price, cost_price from dw.products_dim")
print(f'Number of products:{len(product_ids_set)}')

day = 0
order_qty_day_min = order_qty_day_start = 160     # min order qty per day, start for 2016                   
factor_orders_day = 0.05    # increase factor 5% pro month
month = 1
month_act = 0

for day in range(1):#(len(date_set)):
    print(f"Date: {date_set[day][0]}, Month: {date_set[day][1]}")      # info
    order_date = date_set[day][0]
    order_date_str = order_date.strftime('%Y-%m-%d')
    print(order_date_str)
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
        order_customer_id = customer_ids_set[customer-1][0]
        sku_qty = random.randint(1, 5) #generate qty of SKU in order
        sku_order = random.sample(range(1, len(product_ids_set)), sku_qty) # generate number of product_ids for each order
        print(f'there are {len(sku_order)} SKUs in order')
        shipment_set = [] #list product_id to be shipment to customer
        backorder_set = [] #list product_id to be noted in backorder
        
        # read inventory
        inventory_set = conn.run("select product_id from sandbox.inventory_fact where quantity > 0")
        print(f'Number of products on stock: {len(inventory_set)}')
        inventory_set = list(itertools.chain.from_iterable(inventory_set)) #change to flat_list

        #checking stock availability
        for sku in sku_order:
            if product_ids_set[sku-1][0] in inventory_set:
                shipment_set.append(product_ids_set[sku-1][0])
            else:
                backorder_set.append(product_ids_set[sku-1][0])        

        if backorder_set:
            print(f'to backorder: {backorder_set}')
            backorder_str = ', '.join(map(str, backorder_set)) # Преобразование списка backorder в строку с форматированием
        
        if shipment_set:
            # create new order_id
            conn.run("START TRANSACTION")
            try: 
                # формирование записи в таблицу sandbox.orders_fact + получить order_id 
                conn.run(f'insert into sandbox.orders_fact(order_date, customer_id, expenses) VALUES (:order_date, {order_customer_id}, {expenses});', order_date = order_date_str)
                #print("Данные успешно вставлены") 
            except pg8000.exceptions.DatabaseError as e: 
                print(f"Ошибка при выполнении запроса: {e}")
                       
            # getting new order_id          
            get_order_id_query = """select order_id from sandbox.orders_fact
                                    where created_at = (select max(created_at) from sandbox.orders_fact)"""
            
            order_id = conn.run(get_order_id_query)[0][0]

            print(f'for order_id {order_id} to shipment: {shipment_set}')
            shipment_set_str = ', '.join(map(str, shipment_set)) # Преобразование списка shipment в строку с форматированием
            
            # читаю со склада себестоимость cost_price, доступный остаток quantity    
            sql_query = f"""SELECT inv_prod_id, inv_cost_price, quantity, price 
                            FROM (
                                  (select product_id as inv_prod_id, cost_price as inv_cost_price, quantity from sandbox.inventory_fact
	                               where product_id in ({shipment_set_str})) inv
	                            left join dw.products_dim pd on inv_prod_id = pd.product_id 
	                            ) t1 """
            
            # getting list of list from inventory
            sales_set = conn.run(sql_query)
            #print(f'rows in set: {len(sales_set)}')
            conn.run("COMMIT")  

            # creating an order list to write in sales_fact            
            for row in range(len(sales_set)):
                """print(f'product_id: {sales_set[row][0]}')
                print(f'cost_price: {sales_set[row][1]}')
                print(f'quantity: {sales_set[row][2]}')  """           
                inventory_quantity = sales_set[row][2]
                inventory_cost_price = sales_set[row][1]
                product_price = sales_set[row][3]
                sal_product_id = sales_set[row][0]
                sal_quantity = 1
                sal_cost_price = round((inventory_cost_price / inventory_quantity) * sal_quantity, 2)
                sal_price = round(product_price * sal_quantity, 2)
                sal_profit = round(sal_price - sal_cost_price, 2)
                sal_discount = 0
                
                # формирование записей в таблицу sandbox.sales_fact
                conn.run("START TRANSACTION")
                conn.run(f'insert into sandbox.sales_fact (order_id, order_date, product_id, quantity, sales, cogs, profit, discount, customer_id) values({order_id}, :order_date, {sal_product_id}, {sal_quantity}, {sal_price}, {sal_cost_price}, {sal_profit}, {sal_discount}, {order_customer_id});', order_date = order_date_str)
                conn.run("COMMIT")

                new_inventory_quantity = inventory_quantity - sal_quantity
                new_inventory_cost_price = round((inventory_cost_price / inventory_quantity) * new_inventory_quantity,2)

                # update inventory_fact
                conn.run("START TRANSACTION")
                conn.run(f'update sandbox.inventory_fact set quantity = {new_inventory_quantity}, cost_price = {new_inventory_cost_price} where product_id = {sal_product_id};')
                conn.run("COMMIT")
                print(f'actual qty of product_id {sal_product_id} is: {new_inventory_quantity}')

         
        # формирование записей в таблицу sandbox.backorder_fact если backorder_set не пустой

        
        # изменение записей в таблице sandbox.inventory_fact
# снимок таблицы sandbox.inventory_fact в таблицу sandbox.daily_inventory_fact
# заказы поставщикам


conn.close