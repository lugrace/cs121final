-- [Part H]
-- [Grace Lu - glu@caltech.edu]
-- [Jae Yoon Kim - jaeyoonk@caltech.edu]

-- [Query 1]
-- Most popular products ordered for each day of the week 
-- based on the number of purchases for that product
WITH product_orders AS (
    SELECT product_name, order_day_of_week, COUNT(*) AS num_purchases
    FROM orders NATURAL JOIN products
    GROUP BY product_name, order_day_of_week
    ORDER BY order_day_of_week, num_purchases DESC
),
popular_purchases_per_day AS (
    SELECT order_day_of_week, MAX(num_purchases) AS num_purchases
    FROM product_orders 
    GROUP BY order_day_of_week
)
SELECT order_day_of_week, product_name 
FROM popular_purchases_per_day NATURAL JOIN product_orders;

-- [Query 2]
-- Average number of items in a user's cart
WITH items_in_order AS (
    SELECT user_id, order_id, COUNT(*) AS num_items_in_cart
    FROM orders NATURAL JOIN user_orders
    GROUP BY user_id, order_id
)
SELECT user_id, AVG(num_items_in_cart) AS avg_cart_size
FROM items_in_order
GROUP BY user_id;

-- [Query 3]
-- Number of returning customers, so basically customers
-- that have placed more than one order
-- This is related to Query 2 in the RA part. 
WITH orders_per_customer AS (
    SELECT user_id, COUNT(order_id) AS num_orders_per_user 
    FROM (SELECT DISTINCT user_id, order_id
        FROM orders NATURAL JOIN user_orders) t1
    GROUP BY user_id, order_id
)
SELECT * 
FROM orders_per_customer NATURAL JOIN users
WHERE num_orders_per_user > 1;

-- [Query 4]
-- Most popular aisles and number of visits for that aisle
-- This is related to Query 1 in the RA part. 
WITH aisle_info AS (
    SELECT product_id, product_name, aisle_id, aisle
    FROM orders NATURAL JOIN products NATURAL JOIN aisles
)
SELECT aisle_id, aisle, COUNT(*) AS num_aisle_visits 
FROM aisle_info
GROUP BY aisle_id, aisle
ORDER BY num_aisle_visits DESC;

-- [Query 5]
-- Most popular item for each aisle
WITH aisle_info AS (
    SELECT product_id, product_name, aisle_id, aisle
    FROM orders NATURAL JOIN products NATURAL JOIN aisles
),
popular_item_aisle_ct AS (
    SELECT aisle_id, aisle, product_id, product_name, COUNT(*) AS product_ct 
    FROM aisle_info 
    GROUP BY aisle_id, product_id
),
popular_item_per_aisle AS (
    SELECT aisle_id, aisle, product_id, product_name, most_pop_item_ct
    FROM (SELECT aisle_id, MAX(product_ct) AS most_pop_item_ct
    FROM popular_item_aisle_ct
    GROUP BY aisle_id) t1 NATURAL JOIN popular_item_aisle_ct
)
SELECT * 
FROM popular_item_per_aisle
ORDER BY aisle_id ASC;




-- [Part I]
-- [Grace Lu - glu@caltech.edu]
-- [Jae Yoon Kim - jaeyoonk@caltech.edu]

-- [UDF]
-- Given a department we want to find the least popular product.
-- if there are multiple, the one with the largest days_since_prior_order
-- and then the largest product_id since that'd be the most recent arrival.
-- We'd rather drop a product that was added a long time ago than drop a product 
-- that's brand new at our location since that shows that the product cannot sell
-- even over long periods of time.
DROP FUNCTION IF EXISTS unpopular;

DELIMITER !
CREATE FUNCTION unpopular(
    d_department_id BIGINT UNSIGNED
) RETURNS BIGINT UNSIGNED DETERMINISTIC
BEGIN
    DECLARE result BIGINT UNSIGNED;

    WITH in_dept AS 
        (SELECT product_id 
        FROM products 
        WHERE department_id = d_department_id),
    counter AS
        (SELECT orders.product_id, 
            MIN(days_since_prior_order) as min_days_since, 
            COUNT(*) as ctr
        FROM orders NATURAL JOIN in_dept
        GROUP BY orders.product_id)
    SELECT MAX(product_id)  INTO result
    FROM counter
    WHERE ctr = (SELECT MIN(ctr) FROM counter) AND 
        min_days_since = (SELECT MAX(min_days_since) FROM counter);
    
    RETURN result;
END !
DELIMITER ;

-- CHECKING CODE

-- dept with highest orders is 4, 16, 19
-- SELECT department_id, COUNT(*)
-- FROM products NATURAL JOIN orders
-- GROUP BY department_id
-- ORDER BY COUNT(*) DESC;

-- WITH in_dept AS 
--     (SELECT product_id 
--     FROM products 
--     WHERE department_id = 4),
-- counter AS
--     (SELECT orders.product_id, 
--         MIN(days_since_prior_order) as min_days_since, 
--         COUNT(*) as ctr
--     FROM orders NATURAL JOIN in_dept
--     GROUP BY orders.product_id)
-- SELECT MAX(product_id) 
-- FROM counter
-- WHERE ctr = (SELECT MIN(ctr) FROM counter) AND 
--     min_days_since = (SELECT MAX(min_days_since) FROM counter);

-- SELECT unpopular(4);

-- [UDF 2]
-- Procedure that returns both the number of orders a user has 
-- and the average number of products in their orders
-- We want this returned in a human readable format aka a string
-- so that a non computer person would be able to understand.

DROP FUNCTION IF EXISTS user_order_behavior;

DELIMITER !
CREATE FUNCTION user_order_behavior(
    input_user_id BIGINT UNSIGNED
) RETURNS CHAR(86) DETERMINISTIC
BEGIN
    DECLARE avg_num DECIMAL(8, 2);
    DECLARE num_orders BIGINT UNSIGNED;

    SELECT COUNT(*) INTO num_orders
    FROM user_orders
    WHERE user_orders.user_id = input_user_id ;
    
    SELECT COUNT(product_id) / num_orders INTO avg_num
    FROM orders 
    WHERE order_id in (
        SELECT order_id
        FROM user_orders
        WHERE user_id = input_user_id );

    
    RETURN CONCAT(
        "Average number of products per order: ",
        CAST(avg_num AS CHAR(10)), 
        ", ",
        "Number of orders ordered: ",
        CAST(num_orders AS CHAR(10)));
END !
DELIMITER ;

-- CHECKING CODE
-- SELECT user_id, COUNT(*) 
-- FROM orders NATURAL JOIN user_orders 
-- GROUP BY user_id 
-- ORDER BY COUNT(*) DESC;
-- SELECT user_order_behavior(56463);

-- [Procedure]
-- top 10 bought items get moved to a new aisle
-- the store manager wants to group the top 10 most purchased
-- item and put it into a new aisle.


DROP PROCEDURE IF EXISTS move_top_ten;

DELIMITER !
CREATE PROCEDURE move_top_ten()
BEGIN
    DECLARE new_aisle_id BIGINT UNSIGNED;
    -- add a new aisle
    SET new_aisle_id = (SELECT MAX(aisle_id) + 1 
                        FROM aisles);
                        
    INSERT INTO aisles VALUES(new_aisle_id, 'TOP TEN AISLE!!');
    
    -- move the ten
    DROP TABLE IF EXISTS top_ten;

    CREATE TEMPORARY TABLE top_ten    
    SELECT product_id
    FROM orders
    GROUP BY product_id
    ORDER BY COUNT(*) DESC
    LIMIT 10;
    
    -- SET foreign_key_checks = 0;
    UPDATE products
    SET aisle_id = new_aisle_id
    WHERE product_id IN (
        SELECT product_id FROM top_ten
        );
    -- SET foreign_key_checks = 1;
END !
DELIMITER ;

-- CHECKING CODE
-- SELECT orders.product_id, COUNT(*), aisle_id
-- FROM orders LEFT JOIN 
--     products ON orders.product_id = products.product_id
-- GROUP BY orders.product_id
-- ORDER BY COUNT(*) DESC
-- LIMIT 10;

-- SELECT MAX(aisle_id)
-- FROM aisles;

-- CALL move_top_ten();



-- [Trigger]
-- When an order is deleted from the orders table we must update a user table.
-- if there's no orders at all from ther user, delete the user too. 

DROP TRIGGER IF EXISTS delete_order_trg;

DELIMITER !
CREATE TRIGGER delete_order_trg BEFORE DELETE ON orders
FOR EACH ROW 
BEGIN 
    DECLARE d_user_id BIGINT UNSIGNED;
    SET d_user_id = (SELECT user_id FROM user_orders WHERE order_id = OLD.order_id);
    -- one more order left then delete it from uses database
    IF ((SELECT COUNT(*) FROM user_orders WHERE user_id = d_user_id) <= 1 ) THEN
        SET foreign_key_checks = 0;
        DELETE FROM user_orders WHERE user_id = d_user_id;
        DELETE FROM users WHERE user_id = d_user_id;
        SET foreign_key_checks = 1;
    END IF;
END !
DELIMITER ;


-- CHECKING CODE
-- INSERT INTO users VALUES (6969, 'Barack');
-- INSERT INTO orders VALUES(null, 13176,6,0,4,4,10,9);
-- SELECT * FROM orders ORDER BY order_id DESC;
-- -- new order id is 4268
-- INSERT INTO user_orders VALUES(6969, 4268);
-- SELECT * FROM user_orders WHERE user_id = 6969;
-- DELETE FROM orders WHERE order_id = 4268;
-- -- Checking
-- SELECT * FROM user_orders WHERE user_id = 6969;
-- SELECT * FROM orders WHERE order_id = 4268;
-- SELECT * FROM users WHERE user_id = 6969;


-- [Trigger 2]
-- When an aisle is deleted, we want to move all of those products to a 
-- different aisle so that the customers can still buy them.

DROP TRIGGER IF EXISTS delete_aisle_trg;

DELIMITER !
CREATE TRIGGER delete_aisle_trg BEFORE DELETE ON aisles
FOR EACH ROW 
BEGIN 
    DECLARE default_aisle_id BIGINt UNSIGNED;
    SET default_aisle_id = (SELECT aisle_id FROM aisles WHERE aisle_id <> OLD.aisle_id ORDER BY aisle_id ASC LIMIT 1);
    
    UPDATE products
    SET aisle_id = default_aisle_id
    WHERE aisle_id = OLD.aisle_id;
END !
DELIMITER ;

-- CHECKING CODE
-- SELECT * FROM products WHERE aisle_id = 120;
-- DELETE FROM aisles WHERE aisle_id = 120;
-- SELECT * FROM products WHERE product_id = 459;
-- SELECT * FROM products WHERE aisle_id = 120;




