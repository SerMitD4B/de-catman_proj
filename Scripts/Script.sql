
-- ************************************** calendar_dim

CREATE TABLE dw.calendar_dim
(
 date_id  serial NOT NULL,
 year     int NOT NULL,
 quarter  int NOT NULL,
 month    int NOT NULL,
 week     int NOT NULL,
 "date"   date NOT NULL,
 week_day varchar(20) NOT NULL,
 leep     varchar(20) NOT NULL,
 CONSTRAINT PK_calendar_dim PRIMARY KEY ( date_id )
);

-- ************************************** group_dim

CREATE TABLE dw.group_dim
(
 group_id    serial NOT NULL,
 group_name  varchar(100) NOT NULL,
 description text NULL,
 created_at  timestamp NOT NULL,
 CONSTRAINT PK_group_dim PRIMARY KEY ( group_id )
);

-- *************************************** category_dim
drop table dw.category_dim cascade

CREATE TABLE dw.category_dim
(
 category_id   serial NOT NULL,
 category_name varchar(100) NOT NULL,
 description   text NOT NULL,
 created_at    timestamp NOT NULL,
 group_id      int NOT NULL,
 CONSTRAINT PK_category_dim PRIMARY KEY ( category_id ),
 CONSTRAINT FK_group_dim FOREIGN KEY ( group_id ) REFERENCES group_dim ( group_id )
);

CREATE INDEX FK_group_dim ON category_dim
(
 group_id
);

-- ************************************** geo_dim
drop table dw.geo_dim cascade

CREATE TABLE geo_dim
(
 geo_id  serial NOT NULL,
 country varchar(50) NOT NULL,
 city    varchar(50) NOT NULL,
 CONSTRAINT PK_geo_dim PRIMARY KEY ( geo_id )
);

-- ************************************** customers_dim
CREATE TABLE dw.customers_dim
(
 customer_id   serial NOT NULL,
 customer_name varchar(100) NOT NULL,
 email         varchar(100) NULL,
 phone         varchar(20) NULL,
 geo_id        int NOT NULL,
 CONSTRAINT PK_customers_dim PRIMARY KEY ( customer_id ),
 CONSTRAINT FK_geo_dim FOREIGN KEY ( geo_id ) REFERENCES geo_dim ( geo_id )
);

CREATE INDEX FK_geo_dim ON dw.customers_dim
(
 geo_id
);


-- ************************************** suppliers_dim

CREATE TABLE dw.suppliers_dim
(
 supplier_id    serial NOT NULL,
 supplier_name  varchar(50) NOT NULL,
 email          varchar(100) NOT NULL,
 lead_time      int NOT NULL,
 delay_time     int NOT NULL,
 delivery_cycle int NOT NULL,
 geo_id         int NOT NULL,
 CONSTRAINT PK_suppliers_dim PRIMARY KEY ( supplier_id ),
 CONSTRAINT FK_geo_dim FOREIGN KEY ( geo_id ) REFERENCES geo_dim ( geo_id )
);

CREATE INDEX FK_suppl_geo_dim ON dw.suppliers_dim
(
 geo_id
);


-- ************************************** products_dim
CREATE TABLE dw.products_dim
(
 product_id       serial NOT NULL,
 product_name     varchar(100) NOT NULL,
 description      text NULL,
 price            numeric(12,2) NOT NULL,
 cost_price       numeric(12,2) NOT NULL,
 reorder_level    int NOT NULL,
 reorder_quantity int NOT NULL,
 category_id      int NOT NULL,
 supplier_id      int NOT NULL,
 CONSTRAINT PK_products_dim PRIMARY KEY ( product_id ),
 CONSTRAINT FK_category_dim FOREIGN KEY ( category_id ) REFERENCES category_dim ( category_id ),
 CONSTRAINT FK_suppliers_dim FOREIGN KEY ( supplier_id ) REFERENCES suppliers_dim ( supplier_id )
);

CREATE INDEX FK_category_dim ON products_dim
(
 category_id
);

CREATE INDEX FK_suppliers_dim ON products_dim
(
 supplier_id
);

-- ************************************** sales_fact
CREATE TABLE dw.sales_fact
(
 sales_id    serial NOT NULL,
 order_id    int NOT NULL,
 order_date  date NOT NULL,
 product_id  int NOT NULL,
 quantity    int NOT NULL,
 sales       numeric(12,2) NOT NULL,
 cogs        numeric(12,2) NOT NULL,
 profit      numeric(12,2) NOT NULL,
 discount    numeric(12,2) NOT NULL,
 expenses    numeric(12,2) NOT NULL,
 customer_id int NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( sales_id ),
 CONSTRAINT FK_products_dim FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id ),
 CONSTRAINT FK_customers_dim FOREIGN KEY ( customer_id ) REFERENCES customers_dim ( customer_id )
);

CREATE INDEX FK_products_dim ON sales_fact
(
 product_id
);

CREATE INDEX FK_customers_dim ON sales_fact
(
 customer_id
);


-- ************************************** inventory_fact
CREATE TABLE dw.inventory_fact
(
 inventory_id serial NOT NULL,
 quantity     int NOT NULL,
 cost_price   numeric(12,2) NOT NULL,
 created_at   timestamp NOT NULL,
 product_id   int NOT NULL,
 CONSTRAINT PK_inventory_fact PRIMARY KEY ( inventory_id ),
 CONSTRAINT FK_inventory_products_dim FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id )
);

CREATE INDEX FK_inventory_products_dim ON inventory_fact
(
 product_id
);

-- ************************************** daily_inventory_fact
CREATE TABLE dw.daily_inventory_fact
(
 daily_inventory_id serial NOT NULL,
 product_id         int NOT NULL,
 quantity           int NOT NULL,
 cost_price         numeric(12,2) NOT NULL,
 inventory_date     date NOT NULL,
 created_at         timestamp NOT NULL,
 CONSTRAINT PK_daily_inventory_fact PRIMARY KEY ( daily_inventory_id ),
 CONSTRAINT FK_daily_inventory_products_dim FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id )
);

CREATE INDEX FK_daily_inventory_products_dim ON daily_inventory_fact
(
 product_id
);

-- ************************************** promo_campaign_fact
CREATE TABLE dw.promo_campaign_fact
(
 promo_id    serial NOT NULL,
 description text NOT NULL,
 date_start  date NOT NULL,
 date_end    date NOT NULL,
 discount    int NOT NULL,
 budget      numeric(12,2) NOT NULL,
 CONSTRAINT PK_promo_campaign_fact PRIMARY KEY ( promo_id )
);


CREATE TABLE dw.promo_campaign_set_fact
(
 sett_id     serial NOT NULL,
 promo_id    int NOT NULL,
 geo_id      int NOT NULL,
 category_id int NOT NULL,
 supplier_id int NOT NULL,
 CONSTRAINT PK_promo_campaign_set_fact PRIMARY KEY ( sett_id ),
 CONSTRAINT FK_promo_campaign_fact FOREIGN KEY ( promo_id ) REFERENCES promo_campaign_fact ( promo_id ),
 CONSTRAINT FK_promo_cam_set_fact_geo_dim FOREIGN KEY ( geo_id ) REFERENCES geo_dim ( geo_id ),
 CONSTRAINT FK_promo_cam_set_fact_category_dim FOREIGN KEY ( category_id ) REFERENCES category_dim ( category_id ),
 CONSTRAINT FK_promo_cam_set_fact_suppliers_dim FOREIGN KEY ( supplier_id ) REFERENCES suppliers_dim ( supplier_id )
);

CREATE INDEX FK_promo_campaign_fact ON promo_campaign_set_fact
(
 promo_id
);

CREATE INDEX FK_promo_cam_set_fact_geo_dim ON promo_campaign_set_fact
(
 geo_id
);

CREATE INDEX FK_promo_cam_set_fact_category_dim ON promo_campaign_set_fact
(
 category_id
);

CREATE INDEX FK_promo_cam_set_fact_suppliers_dim ON promo_campaign_set_fact
(
 supplier_id
);


