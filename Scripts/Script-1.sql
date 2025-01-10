
insert into dw.group_dim (group_name, description)
select group_name, description from public_old.product_groups

insert into dw.category_dim (category_id, category_name, group_id, description)
values
(1, 'BRAKE SYSTEM DETAILS', 14, 'Детали тормозной системы'),
(2, 'FILTERS_AIR', 15, 'Фильтры возд'),
(3, 'FILTERS_CAB', 15, 'Фильтры каб'),
(4, 'FILTERS_FUEL', 15, 'Фильтры топл'),
(5, 'FILTERS_OIL', 15, 'Фильтры '),
(6, 'ENGINE DETAILS ', 16, 'Детали двигателя '),
(7, 'OIL PUMPS ', 16, 'Насосы масляные '),
(8, 'AXLES TRAILERS', 17, 'Оси к прицепам и полуприцепам'),
(9, 'OTHER AXLES DETAILS', 17, 'Детали мостов прочие'),
(10, 'SHOCK ABSORBERS', 18, 'Амортизаторы'),
(11, 'SPRINGS', 18, 'Рессоры'),
(12, 'SUSPENSION AND STEERING DETAILS ', 18, 'Детали подвески и рулевого управления '),
(13, 'CLUTCHES ', 19, 'Сцепления '),
(14, 'GEARBOX DETAILS', 19, 'Детали КПП '),
(15, 'BEARINGS ROLLERS TENSIONERS ', 20, 'Подшипники, ролики, натяжители '),
(16, 'GASKETS AND SEALS ', 21, 'Прокладки и уплотнения '),
(17, 'SENSORS ', 22, 'Датчики '),
(18, 'FANS', 23, 'Вентиляторы'),
(19, 'RADIATORS ', 23, 'Радиаторы '),
(20, 'THERMOSTATS', 23, 'Термостаты'),
(21, 'WATER PUMPS', 23, 'Насосы водяные'),
(22, 'FASTENERS', 24, 'Крепёжные элементы'),
(23, 'GLASS', 24, 'Стёкла '),
(24, 'MIRRORS', 24, 'Зеркала'),
(25, 'OPTICS', 24, 'Оптика '),
(26, 'BATTERY', 25, 'АКБ'),
(27, 'ELECTRIC_MOTORS', 25, 'Электромоторы'),
(28, 'ELECTRICAL_EQUIPMENT_OTHER', 25, 'Электрооборудование прочее'),
(29, 'GENERATORS', 25, 'Генераторы'),
(30, 'GLOW_PLUGS', 25, 'Свечи накаливания'),
(31, 'IGNITION_COILS', 25, 'Распределители и катушки зажигания'),
(32, 'IGNITION_WIRES', 25, 'Провода зажигания'),
(33, 'LAMPS', 25, 'Лампы'),
(34, 'SOUND_ALARM_DEVICES', 25, 'Приборы звуковой сигнализации'),
(35, 'SPARK_PLUGS', 25, 'Свечи зажигания'),
(36, 'STARTERS', 25, 'Стартеры');


insert into dw.geo_dim (geo_id, country, city)
values
(1,'Argentina', 'Buenos Aires'),
(2,'Australia', 'Canberra'),
(3,'Austria', 'Vienna'),
(4,'Belgium', 'Brussels'),
(5,'Brazil', 'Brasilia'),
(6,'Canada', 'Ottawa'),
(7,'China', 'Beijing'),
(8,'Egypt', 'Cairo'),
(9,'France', 'Paris'),
(10,'Germany', 'Berlin'),
(11,'India', 'New Delhi'),
(12,'Indonesia', 'Jakarta'),
(13,'Ireland', 'Dublin'),
(14,'Italy', 'Rome'),
(15,'Japan', 'Tokyo'),
(16,'Mexico', 'Mexico City'),
(17,'Netherlands', 'Amsterdam'),
(18,'Nigeria', 'Abuja'),
(19,'Norway', 'Oslo'),
(20,'Poland', 'Warsaw'),
(21,'Russia', 'Moscow'),
(22,'Singapore', 'Singapore'),
(23,'South Korea', 'Seoul'),
(24,'Spain', 'Madrid'),
(25,'Sweden', 'Stockholm'),
(26,'Thailand', 'Bangkok'),
(27,'Turkey', 'Ankara');

-- list of suppliers
insert into dw.suppliers_dim(supplier_id,supplier_name,email,lead_time,delay_time,delivery_cycle,geo_id)
select s.supplier_id, s.supplier_name, s.email, s.lead_time, s.delay_time, s.delivery_cycle, gd.geo_id 
from public_old.suppliers s 
join dw.geo_dim gd 
on s.city = gd.country 
order by s.supplier_id 

-- list of products
insert into dw.products_dim (product_id, product_name, price, cost_price, reorder_level, reorder_quantity, category_id, supplier_id)
select product_id, product_name, price, cost_price, reorder_level, reorder_quantity, category_id, supplier_id from public_old.products p 

-- list of customers 
insert into dw.customers_dim (customer_id, customer_name, geo_id)
select c.customer_id, c.customer_name, gd.geo_id--, gd.country 
from public_old.customers c 
join dw.geo_dim gd
on c.country = gd.country 

select 
	distinct t1.country as customer_country,
	count(t1.customer_id) as qty_in_country
from (
select *
	from dw.customers_dim cd
	left join dw.geo_dim gd 
	using(geo_id)
) t1
group by 1
order by 2 desc 

-- data to inventory
insert into dw.inventory_fact (inventory_id, product_id, quantity, cost_price)
select inventory_id, product_id, quantity, cost_price_amount from public_old.inventory i 

-- calendar
--truncate table dw.calendar_dim;
--
insert into dw.calendar_dim 
select 
	to_char(date,'yyyymmdd')::int as date_id,  
    extract('year' from date)::int as year,
    extract('quarter' from date)::int as quarter,
    extract('month' from date)::int as month,
    extract('week' from date)::int as week,
    date::date,
    to_char(date, 'dy') as week_day,
    CASE 
	     WHEN (extract('year' FROM date)::int % 4 = 0 AND extract('year' FROM date)::int % 100 != 0) 
	     OR (extract('year' FROM date)::int % 400 = 0) 
	     THEN true 
	     ELSE false 
	END as leap
 from generate_series(date '2016-01-01',
                      date '2030-01-01',
                      interval '1 day')
 as t(date);
      
--checking
select 
distinct year, count(week_day) 
from dw.calendar_dim
group by 1

-- create table in sandbox
create table sandbox.sales_fact as table dw.sales_fact
with no data

-- orders_fact
create table dw.orders_fact
(
 order_id serial not null,
 order_date date not null,
 expences numeric(12,2),
 customer_id int not null,
 created_at timestamp default current_timestamp,
 constraint PK_orders_fact primary key (order_id),
 constraint FK_orders_fact_customers_dim foreign key (customer_id) references dw.customers_dim (customer_id)
)

-- backorders_fact
create table dw.backorders_fact
(
 backorder_id serial not null,
 quantity int not null,
 date_backorder date not null,
 product_id int not null,
 customer_id int not null,
 constraint PK_backorders_fact primary key (backorder_id),
 constraint FK_backorders_fact_products_dim foreign key (product_id) references dw.products_dim (product_id),
 constraint FK_backorders_fact_customers_dim foreign key (customer_id) references dw.customers_dim (customer_id) 
)

--sandbox
create table sandbox.backorders_fact as 
select * 
from dw.backorders_fact bf 

create table sandbox.orders_fact as
select *
from dw.orders_fact of2 

drop table sandbox.sales_fact

create table sandbox.sales_fact as
select * 
from dw.sales_fact sf 

create table sandbox.daily_inventory_fact as
select *
from dw.daily_inventory_fact dif 
