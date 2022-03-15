-- [Part B]
-- [Grace Lu - glu@caltech.edu]
-- [Jae Yoon Kim - jaeyoonk@caltech.edu]

-- DROP TABLE commands:
DROP TABLE IF EXISTS user_orders;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS aisles;

-- CREATE TABLE commands:

-- This table stores information on the users
-- that are placing the order. 
-- user_id: unique id that represents the customer
-- name: first name of the customer.
CREATE TABLE users (
    user_id     SERIAL,
    name        VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id)
);

-- This table records the departments in the grocery store
-- department_id: unique id that represents the department
-- department: name of the department (ie, produce)
CREATE TABLE departments (
    department_id     SERIAL,
    department        VARCHAR(50) NOT NULL,
    PRIMARY KEY (department_id)
);

-- This table records the aisles in the grocery store
-- aisle_id: unique id that represents the aisle
-- aisle: name of the aisle (ie, fresh fruits)
CREATE TABLE aisles (
    aisle_id     SERIAL,
    aisle        VARCHAR(50) NOT NULL,
    PRIMARY KEY (aisle_id)
);

-- This table records what products are available in the grocery store
-- product_id: unique id that represents the product
-- department_id: unique id that represents the department
-- product_name: represents the name of the product
-- aisle_id: unique id that represents the aisle
CREATE TABLE products (
    product_id          SERIAL,
    department_id       BIGINT UNSIGNED NOT NULL,
    product_name        VARCHAR(200) NOT NULL,
    aisle_id            BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (product_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (aisle_id) REFERENCES aisles(aisle_id)
        -- ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- This table represents the orders to the grocery store 
-- and are uniquely represented by (order_id, product_id)
-- order_id: unique id that represents the order
-- product_id: unique id that represents the product
-- add_to_cart: order in which product was added to cart
-- reordered: if user has ordered this product before (1 yes/0 no)
-- order_num: what order num the user is on (1 if this is their first order)
-- order_day_of_week: what day of week it was ordered on (0-Monday, 6-Sun)
-- order_hour_of_day: what hour of the day it was ordered (0 to 23)
-- days_since_prior_order: days since last order
--          can be null if order_num = 1
CREATE TABLE orders (
    order_id                BIGINT UNSIGNED AUTO_INCREMENT,
    product_id              BIGINT UNSIGNED,
    add_to_cart             INT NOT NULL,
    reordered               TINYINT NOT NULL,
    order_num               INT NOT NULL,
    order_day_of_week       INT NOT NULL,
    order_hour_of_day       INT NOT NULL,
    days_since_prior_order  INT NULL,
    PRIMARY KEY (order_id, product_id),
    CHECK (reordered IN (0, 1)),
    CHECK (order_num >= 0),
    CHECK (order_day_of_week >= 0 AND order_day_of_week < 7),
    CHECK (order_hour_of_day >= 0 AND order_hour_of_day < 24),
    CHECK (days_since_prior_order >= 0),
    CHECK (add_to_cart >= 0),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE
);

-- This table stores what users are associated with what orders
-- user_id: unique id that represents the customer
-- order_id: unique id that represents the order
CREATE TABLE user_orders (
    user_id     BIGINT UNSIGNED,
    order_id    BIGINT UNSIGNED,
    PRIMARY KEY (user_id, order_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE
);

-- Index
CREATE INDEX order_day_idx ON orders (order_day_of_week);