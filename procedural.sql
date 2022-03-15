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


-- [Procedure]
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
-- SELECT user_id, COUNT(*) FROM orders NATURAL JOIN user_orders GROUP BY user_id ORDER BY COUNT(*) DESC;
-- SELECT user_order_behavior(56463);


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




