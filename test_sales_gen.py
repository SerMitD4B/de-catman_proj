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
date_set = conn.run("SELECT date, month FROM dw.calendar_dim where year = 2017")
print('qty days in year = ', len(date_set))
expenses = 3 # additional expenses pro order in 2016

# read all customers ID
customer_ids_set = conn.run("select customer_id from dw.customers_dim")
print(f'Number of Customers:{len(customer_ids_set)}')

# read products
#product_ids_set = conn.run("select product_id, price, cost_price from dw.products_dim where reorder_quantity > 0")
#print(f'Number of products:{len(product_ids_set)}')

day = 0
order_qty_day_min = order_qty_day_start = 700   # min order qty per day, start for 2016                   
factor_orders_day = 0.05    # increase factor 3% pro month
month = 1
month_act = 0

for day in range(len(date_set)): #range(60):
    count_sku_ship = 0
    count_sku_backorder = 0
    print(f"Sim_Date: {date_set[day][0]}, Num_Month: {date_set[day][1]}, Real_time: {datetime.datetime.now()}")      # info
    order_date = date_set[day][0]
    order_date_str = order_date.strftime('%Y-%m-%d')
#    print(order_date_str)
    # calculation of min limit of the qty of order monthly, qty orders increases monthly for 5%.
    month = date_set[day][1] # number of month
    if month != month_act:
        month_act = month
        order_qty_day_min = order_qty_day_min + round(order_qty_day_start * ((month_act - 1) * factor_orders_day))
        # read products set
        product_ids_set = conn.run("select product_id, price, cost_price from dw.products_dim where reorder_quantity > 0")
        print(f'Number of products:{len(product_ids_set)}')
    
    #random qty orders per each day-  diff between min and max = 20%.
    order_qty = random.randint(order_qty_day_min, round(order_qty_day_min * 1.2)) 
    print('qty orders per day = ', order_qty) #info
    
    #generating a random sequence of indexes for sampling from a customer_ids_set  
    if order_qty > len(customer_ids_set): 
        customer_ids = [random.randint(1, len(customer_ids_set)) for _ in range(order_qty)] # генерируем последовательность индексов 1 до N(кол-во клиентов в БД)
        print("there are customers who have more than 1 order per day") 
    else: 
        try:
            customer_ids = random.sample(range(1, len(customer_ids_set) + 1), order_qty) 
    #        print(customer_ids) 
        except ValueError as qty_order_err: 
            print(f"Ошибка: {qty_order_err}")
    
    """
    ошибка была из-за того, что количество клиентов меньше кол-ва заказов
    в алгоритм заложена логика - один клиент делает один заказ в день.
    при кол-ве заказов в день более чем кол-во клиентов, клиенты могут делать больше 1 заказа в ден
    """
#    print('customer ids: ', customer_ids)
    print('qty customers per day = ', len(customer_ids))
 
    #generate order set for each customer
    for customer in (customer_ids):
#        print(f'Customer_id: {customer_ids_set[customer-1][0]}')
        order_customer_id = customer_ids_set[customer-1][0]  #здесь ошибка!!
        sku_qty = random.randint(1, 5) #generate qty of SKU in order
        sku_order = random.sample(range(1, len(product_ids_set)), sku_qty) # generate number of product_ids for each order
#        print(f'there are {len(sku_order)} SKUs in order')
        shipment_set = [] #list product_id to be shipment to customer
        backorder_set = [] #list product_id to be noted in backorder
        
        # read inventory
        inventory_set = conn.run("select product_id from sandbox.inventory_fact where quantity > 0")
#        print(f'Number of products on stock: {len(inventory_set)}')
        inventory_set = list(itertools.chain.from_iterable(inventory_set)) #change to flat_list

        #checking stock availability
        for sku in sku_order:
            if product_ids_set[sku-1][0] in inventory_set:
                shipment_set.append(product_ids_set[sku-1][0])
            else:
                backorder_set.append(product_ids_set[sku-1][0])        

        if backorder_set:          # формирование записей в таблицу sandbox.backorder_fact если backorder_set не пустой
            #print(f'to backorder: {backorder_set}')
            count_sku_backorder += len(backorder_set)
            backorder_str = ', '.join(map(str, backorder_set)) # Преобразование списка backorder в строку с форматированием
            # creating an order list to write in sales_fact            
            for row in range(len(backorder_set)):
                back_product_id = backorder_set[row]
                back_quantity = 1
                # формирование записей в таблицу sandbox.backorders_fact
                conn.run("START TRANSACTION")
                try:
                    conn.run(f'insert into sandbox.backorders_fact (date_backorder, product_id, quantity, customer_id) values(:order_date, {back_product_id}, {back_quantity}, {order_customer_id});', order_date = order_date_str)
                except pg8000.exceptions.DatabaseError as er: 
                    print(f"Ошибка при выполнении записи в backorders_fact: {er}")
                conn.run("COMMIT")      
        
        if shipment_set:
            count_sku_ship += len(shipment_set)
            #print(f'to shipment: {shipment_set}')
            # create new order_id
            conn.run("START TRANSACTION")
            try: 
                # формирование записи в таблицу sandbox.orders_fact + получить order_id 
                conn.run(f'insert into sandbox.orders_fact(order_date, customer_id, expenses) VALUES (:order_date, {order_customer_id}, {expenses});', order_date = order_date_str)
            except pg8000.exceptions.DatabaseError as e: 
                print(f"Ошибка при выполнении запроса: {e}")
                       
            # getting new order_id          
            get_order_id_query = """select order_id from sandbox.orders_fact
                                    where created_at = (select max(created_at) from sandbox.orders_fact)"""
            order_id = conn.run(get_order_id_query)[0][0]
            
            # Преобразование списка shipment в строку с форматированием
            shipment_set_str = ', '.join(map(str, shipment_set))
            
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
                inventory_quantity = sales_set[row][2] #available stock qty
                inventory_cost_price = sales_set[row][1] #cost of available stock qty
                product_price = sales_set[row][3] #sales price for 1 pc
                sal_product_id = sales_set[row][0] #product_id
                sal_quantity = 1
               #стар. версия sal_cost_price = round((inventory_cost_price / inventory_quantity) * sal_quantity, 2)
                sal_cost_price = (inventory_cost_price / inventory_quantity) * sal_quantity #новая версия
                sal_price = round(product_price * sal_quantity, 2)
                sal_profit = round(sal_price - sal_cost_price, 2)
                sal_discount = 0
                
                # add sales to table sales_fact
                conn.run("START TRANSACTION")
                conn.run(f'insert into sandbox.sales_fact (order_id, order_date, product_id, quantity, sales, cogs, profit, discount, customer_id) values({order_id}, :order_date, {sal_product_id}, {sal_quantity}, {sal_price}, {sal_cost_price}, {sal_profit}, {sal_discount}, {order_customer_id});', order_date = order_date_str)
                conn.run("COMMIT")

                new_inventory_quantity = inventory_quantity - sal_quantity
                #new_inventory_cost_price = round((inventory_cost_price / inventory_quantity) * new_inventory_quantity,2)
                new_inventory_cost_price = inventory_cost_price - sal_cost_price

                # update inventory_fact --- изменение записей в таблице sandbox.inventory_fact
                conn.run("START TRANSACTION")
                conn.run(f'update sandbox.inventory_fact set quantity = {new_inventory_quantity}, cost_price = {new_inventory_cost_price} where product_id = {sal_product_id};')
                conn.run("COMMIT")

    #>---поступление товара на склад---
    sql_update_inventory = """WITH update_stock AS (
                                select 
                                    purchase_id,
                                    purch_fact.product_id,
                                    purch_fact.order_quantity + inv_fact.quantity as new_quantity_stock, 
                                    purch_fact.order_cost + inv_fact.cost_price as new_cost_stock
                                from (
                                    select purchase_id, product_id, order_quantity, order_cost, delivery_date, status
                                    from sandbox.purchase_fact
                                    where status != 'completed'
                                    and delivery_date = TO_DATE(:current_date, 'YYYY-MM-DD')
                                    ) purch_fact
                                    left join (
                                        select product_id, quantity, cost_price
                                        from sandbox.inventory_fact
                                        ) inv_fact
                                        on purch_fact.product_id = inv_fact.product_id
                                        )
                                UPDATE sandbox.inventory_fact 
                                SET 
                                    quantity = update_stock.new_quantity_stock, 
                                    cost_price = update_stock.new_cost_stock 
                                FROM update_stock 
                                WHERE inventory_fact.product_id = update_stock.product_id;
                                """
    conn.run("START TRANSACTION") 
    try: # Обновление записей в таблице inventory_fact  
        conn.run(sql_update_inventory, current_date = order_date_str) 
        conn.run("COMMIT") 
    except pg8000.exceptions.DatabaseError as update_inventory_e: 
        print(f"Ошибка при выполнении запроса обновления записей в inventory_fact: {update_inventory_e}") 
        conn.run("ROLLBACK") 

    sql_update_purch_status = """WITH update_status AS (
                                select purchase_id, product_id, order_quantity, order_cost, delivery_date, status
                                from sandbox.purchase_fact
                                where status != 'completed'
                                and delivery_date = TO_DATE(:current_date, 'YYYY-MM-DD')
                                )
                                update sandbox.purchase_fact
                                set
                                    status = 'completed'
                                from update_status
                                where sandbox.purchase_fact.purchase_id = update_status.purchase_id
                                """
   
    conn.run("START TRANSACTION") 
    try: # обновление записей в таблице purchase_fact 
        conn.run(sql_update_purch_status, current_date = order_date_str) 
        conn.run("COMMIT") 
    except pg8000.exceptions.DatabaseError as update_purch_e: 
        print(f"Ошибка при выполнении запроса обновления записей в purchase_fact: {update_purch_e}") 
        conn.run("ROLLBACK") 
    #---поступление товара на склад---<
    
    #>---creating purchase orders --- формируем заказы поставщикам
    sql_purchase = """  insert into sandbox.purchase_fact (order_date, delivery_date, supplier_id, product_id, order_quantity, order_cost, status)
                        select
                            TO_DATE(:current_date, 'YYYY-MM-DD') as order_date,
                            (TO_TIMESTAMP(:current_date, 'YYYY-MM-DD') + (lead_time * INTERVAL '1 day'))::date as delivery_date,
                            supplier_id,
                            product_id,
                            reorder_quantity as order_quantity,
                            round(cost_price * reorder_quantity, 2) as order_cost,
                            'pending' as status
                        from (
                            select 
                                pd.product_id, 
                                pd.cost_price, -- cost price for 1pc
                                pd.reorder_level, 
                                pd.reorder_quantity, 
                                available_qty,
                                case
                                    when pending_qty is null then 0
                                    else pending_qty
                                end as pending_qty,
                                lead_time,
                                pd.supplier_id
                            from (
                                select * 
                                from dw.products_dim 
                                where reorder_level > 0
                                ) pd
                                left join ( --actual available stock qty
                                    select 
                                        product_id, 
                                        quantity as available_qty 
                                    from sandbox.inventory_fact
                                    ) if2 
                                    on if2.product_id = pd.product_id
                                left join ( --goods are on the way from suppliers
                                    select 
                                        product_id, 
                                        sum(order_quantity) as pending_qty
                                    from sandbox.purchase_fact
                                    where status != 'completed'
                                    group by product_id
                                    ) purch_orders
                                    on if2.product_id = purch_orders.product_id
                                left join (
                                    select supplier_id, lead_time
                                    from dw.suppliers_dim
                                    ) suppl_delivery_time
                                    on suppl_delivery_time.supplier_id = pd.supplier_id
                            order by pd.supplier_id, product_id
                        ) as set_to_purchase
                        where reorder_level > (available_qty + pending_qty)
    """ 
    conn.run("START TRANSACTION")
    try: # формирование списка позиций для заказа поставщикам Purchase_order
        sql_purchase_volumes = conn.run(sql_purchase, current_date = order_date_str) 
    except pg8000.exceptions.DatabaseError as purchase_e: 
        print(f"Ошибка при выполнении запроса Purchase_orders: {purchase_e}")
    conn.run("COMMIT")
    #---creating purchase orders ---< формируем заказы поставщикам

    #>--- daily inventory--- снимок таблицы sandbox.inventory_fact в таблицу sandbox.daily_inventory_fact
    conn.run("START TRANSACTION")
    daily_inv_upd_query = f"""insert into sandbox.daily_inventory_fact (product_id, quantity, cost_price, inventory_date)
                              select product_id, quantity, cost_price, :order_date from sandbox.inventory_fact"""
    conn.run(daily_inv_upd_query, order_date = order_date_str)
    conn.run("COMMIT")
    print(f'count_sku_ship: {count_sku_ship}')
    print(f'count_sku_backorder: {count_sku_backorder}')
    print('-------------------')

    #--- daily inventory---< снимок таблицы sandbox.inventory_fact в таблицу sandbox.daily_inventory_fact

#    conn.close  # убрать после теста с записью заказов поставщикам
#    break
conn.close