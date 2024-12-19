-- ************************* SqlDBM: PostgreSQL *************************
-- *** Generated by SqlDBM: de_catman_proj by sm.dataeng.nw@gmail.com ***


-- ************************************** sales_fact
CREATE TABLE sales_fact
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
 CONSTRAINT PK_10 PRIMARY KEY ( sales_id ),
 CONSTRAINT FK_8 FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id ),
 CONSTRAINT FK_9 FOREIGN KEY ( customer_id ) REFERENCES customers_dim ( customer_id )
);

CREATE INDEX FK_1 ON sales_fact
(
 product_id
);

CREATE INDEX FK_2 ON sales_fact
(
 customer_id
);


-- ************************************** calendar_dim
CREATE TABLE calendar_dim
(
 date_id  serial NOT NULL,
 year     int NOT NULL,
 quarter  int NOT NULL,
 month    int NOT NULL,
 week     int NOT NULL,
 "date"   date NOT NULL,
 week_day varchar(20) NOT NULL,
 leep     varchar(20) NOT NULL,
 CONSTRAINT PK_7 PRIMARY KEY ( date_id )
);

-- ************************************** category_dim
CREATE TABLE category_dim
(
 category_id   serial NOT NULL,
 category_name varchar(100) NOT NULL,
 description   text NOT NULL,
 created_at    timestamp NOT NULL,
 group_id      int NOT NULL,
 CONSTRAINT PK_2 PRIMARY KEY ( category_id ),
 CONSTRAINT FK_1 FOREIGN KEY ( group_id ) REFERENCES group_dim ( group_id )
);

CREATE INDEX FK_1 ON category_dim
(
 group_id
);


-- ************************************** customers_dim
CREATE TABLE customers_dim
(
 customer_id   serial NOT NULL,
 customer_name varchar(100) NOT NULL,
 email         varchar(100) NULL,
 phone         varchar(20) NULL,
 geo_id        int NOT NULL,
 CONSTRAINT PK_6 PRIMARY KEY ( customer_id ),
 CONSTRAINT FK_5_1 FOREIGN KEY ( geo_id ) REFERENCES geo_dim ( geo_id )
);

CREATE INDEX FK_1 ON customers_dim
(
 geo_id
);


-- ************************************** daily_inventory_fact
CREATE TABLE daily_inventory_fact
(
 daily_inventory_id serial NOT NULL,
 product_id         int NOT NULL,
 quantity           int NOT NULL,
 cost_price         numeric(12,2) NOT NULL,
 inventory_date     date NOT NULL,
 created_at         timestamp NOT NULL,
 CONSTRAINT PK_9 PRIMARY KEY ( daily_inventory_id ),
 CONSTRAINT FK_7_1 FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id )
);

CREATE INDEX FK_1 ON daily_inventory_fact
(
 product_id
);


-- ************************************** geo_dim
CREATE TABLE geo_dim
(
 geo_id  serial NOT NULL,
 country varchar(50) NOT NULL,
 city    varchar(50) NOT NULL,
 CONSTRAINT PK_5 PRIMARY KEY ( geo_id )
);

-- ************************************** group_dim
CREATE TABLE group_dim
(
 group_id    serial NOT NULL,
 group_name  varchar(100) NOT NULL,
 description text NULL,
 created_at  timestamp NOT NULL,
 CONSTRAINT PK_1 PRIMARY KEY ( group_id )
);

-- ************************************** inventory_fact
CREATE TABLE inventory_fact
(
 inventory_id serial NOT NULL,
 quantity     int NOT NULL,
 cost_price   numeric(12,2) NOT NULL,
 created_at   timestamp NOT NULL,
 product_id   int NOT NULL,
 CONSTRAINT PK_8 PRIMARY KEY ( inventory_id ),
 CONSTRAINT FK_7 FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id )
);

CREATE INDEX FK_1 ON inventory_fact
(
 product_id
);

-- ************************************** promo_campaign_fact
CREATE TABLE promo_campaign_fact
(
 promo_id    serial NOT NULL,
 description text NOT NULL,
 date_start  date NOT NULL,
 date_end    date NOT NULL,
 discount    int NOT NULL,
 budget      numeric(12,2) NOT NULL,
 CONSTRAINT PK_12 PRIMARY KEY ( promo_id )
);

-- ************************************** promo_campaign_set_fact
CREATE TABLE promo_campaign_set_fact
(
 sett_id      NOT NULL,
 promo_id    int NOT NULL,
 geo_id      int NOT NULL,
 category_id int NOT NULL,
 supplier_id int NOT NULL,
 CONSTRAINT PK_14 PRIMARY KEY ( sett_id ),
 CONSTRAINT FK_15 FOREIGN KEY ( promo_id ) REFERENCES promo_campaign_fact ( promo_id ),
 CONSTRAINT FK_14_1 FOREIGN KEY ( geo_id ) REFERENCES geo_dim ( geo_id ),
 CONSTRAINT FK_15_1 FOREIGN KEY ( category_id ) REFERENCES category_dim ( category_id ),
 CONSTRAINT FK_16 FOREIGN KEY ( supplier_id ) REFERENCES suppliers_dim ( supplier_id )
);

CREATE INDEX FK_1 ON promo_campaign_set_fact
(
 promo_id
);

CREATE INDEX FK_2 ON promo_campaign_set_fact
(
 geo_id
);

CREATE INDEX FK_3 ON promo_campaign_set_fact
(
 category_id
);

CREATE INDEX FK_4 ON promo_campaign_set_fact
(
 supplier_id
);

-- ************************************** promo_sales_fact
CREATE TABLE promo_sales_fact
(
 promo_sales_id serial NOT NULL,
 order_id       int NOT NULL,
 promo_id       int NOT NULL,
 CONSTRAINT PK_13 PRIMARY KEY ( promo_sales_id ),
 CONSTRAINT FK_14 FOREIGN KEY ( promo_id ) REFERENCES promo_campaign_fact ( promo_id )
);

CREATE INDEX FK_1 ON promo_sales_fact
(
 promo_id
);

-- ************************************** purchase_fact
CREATE TABLE purchase_fact
(
 purchase_id   serial NOT NULL,
 order_id      int NOT NULL,
 order_date    date NOT NULL,
 delivery_date date NOT NULL,
 supplier_id   int NOT NULL,
 product_id    int NOT NULL,
 quantity      int NOT NULL,
 cost_price    numeric(12,2) NOT NULL,
 status_id     int NOT NULL,
 created_at    timestamp NOT NULL,
 CONSTRAINT PK_11 PRIMARY KEY ( purchase_id ),
 CONSTRAINT FK_10 FOREIGN KEY ( supplier_id ) REFERENCES suppliers_dim ( supplier_id ),
 CONSTRAINT FK_11 FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id )
);

CREATE INDEX FK_1 ON purchase_fact
(
 supplier_id
);

CREATE INDEX FK_2 ON purchase_fact
(
 product_id
);

-- ************************************** sales_fact
CREATE TABLE sales_fact
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
 CONSTRAINT PK_10 PRIMARY KEY ( sales_id ),
 CONSTRAINT FK_8 FOREIGN KEY ( product_id ) REFERENCES products_dim ( product_id ),
 CONSTRAINT FK_9 FOREIGN KEY ( customer_id ) REFERENCES customers_dim ( customer_id )
);

CREATE INDEX FK_1 ON sales_fact
(
 product_id
);

CREATE INDEX FK_2 ON sales_fact
(
 customer_id
);

-- ************************************** suppliers_dim
CREATE TABLE suppliers_dim
(
 supplier_id    serial NOT NULL,
 supplier_name  varchar(50) NOT NULL,
 email          varchar(100) NOT NULL,
 lead_time      int NOT NULL,
 delay_time     int NOT NULL,
 delivery_cycle int NOT NULL,
 geo_id         int NOT NULL,
 CONSTRAINT PK_4 PRIMARY KEY ( supplier_id ),
 CONSTRAINT FK_4 FOREIGN KEY ( geo_id ) REFERENCES geo_dim ( geo_id )
);

CREATE INDEX FK_1 ON suppliers_dim
(
 geo_id
);
