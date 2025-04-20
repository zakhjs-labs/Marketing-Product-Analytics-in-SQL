WITH canceled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action='cancel_order'
),
p_users AS (
    SELECT 
        time::DATE as date, 
        COUNT(DISTINCT user_id) as paying_users
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
    AND action = 'create_order'
    GROUP BY time::DATE
), single_order AS (
    SELECT
        date,
        COUNT(user_id) as single_order_users
    FROM
        (SELECT 
            time::DATE as date, 
            user_id, 
            COUNT(DISTINCT order_id) as count_orders
        FROM user_actions
        WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
        AND action='create_order'
        GROUP BY time::DATE, user_id
        HAVING COUNT(DISTINCT order_id) = 1) t
    GROUP BY date
)

SELECT 
    date,
    ROUND(100*single_order_users::DECIMAL/paying_users, 2) AS single_order_users_share,
    ROUND(100 - (100*single_order_users::DECIMAL/paying_users), 2) AS several_orders_users_share
FROM p_users pu
LEFT JOIN single_order so USING(date)
ORDER BY date