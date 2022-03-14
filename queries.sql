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
-- Most popular aisles and most popular item in that aisle
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
    SELECT aisle_id, product_id, COUNT(*) AS product_ct 
    FROM aisle_info 
    GROUP BY aisle_id, product_id
),
popular_item_per_aisle AS (
    SELECT aisle_id, product_id, most_pop_item_ct
    FROM (SELECT aisle_id, MAX(product_ct) AS most_pop_item_ct
    FROM popular_item_aisle_ct
    GROUP BY aisle_id) t1 NATURAL JOIN popular_item_aisle_ct
)
SELECT * 
FROM popular_item_per_aisle
ORDER BY aisle_id ASC;