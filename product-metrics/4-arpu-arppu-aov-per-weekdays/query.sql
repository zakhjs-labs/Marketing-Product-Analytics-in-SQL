WITH cancelled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
),

order_products AS (
    SELECT 
        order_id,
        creation_time,
        unnest(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
    AND creation_time BETWEEN '2022-08-26' AND '2022-09-09'
),
weekly_revenue AS (
    SELECT 
        TO_CHAR(creation_time::date, 'Day') AS weekday,
        DATE_PART('isodow', creation_time::date) AS weekday_number,
        COUNT(DISTINCT order_id) AS orders,
        SUM(price) AS revenue
    FROM order_products
    LEFT JOIN products USING (product_id)
    GROUP BY TO_CHAR(creation_time::date, 'Day'), DATE_PART('isodow', creation_time::date)
),
weekly_users AS (
    SELECT 
        TO_CHAR(time::date, 'Day') AS weekday,
        DATE_PART('isodow', time::date) AS weekday_number,
        COUNT(DISTINCT user_id) AS users
    FROM user_actions
    WHERE time BETWEEN '2022-08-26' AND '2022-09-09'
    GROUP BY TO_CHAR(time::date, 'Day'), DATE_PART('isodow', time::date)
),
weekly_paying_users AS (
    SELECT 
        TO_CHAR(time::date, 'Day') AS weekday,
        DATE_PART('isodow', time::date) AS weekday_number,
        COUNT(DISTINCT user_id) AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
    AND time BETWEEN '2022-08-26' AND '2022-09-09'
    GROUP BY TO_CHAR(time::date, 'Day'), DATE_PART('isodow', time::date)
)

SELECT  wr.weekday, wr.weekday_number,
ROUND(revenue/users, 2) AS arpu,
ROUND(revenue/paying_users, 2) AS arppu,
ROUND(revenue/orders, 2) AS aov
FROM weekly_revenue wr
LEFT JOIN weekly_users wu ON wr.weekday_number = wu.weekday_number
LEFT JOIN weekly_paying_users wp ON wr.weekday_number = wp.weekday_number
ORDER BY weekday_number