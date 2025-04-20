WITH canceled_orders AS (
    SELECT order_id 
    FROM user_actions
    WHERE action='cancel_order'
), first_total_orders AS (
    SELECT 
        time::DATE as date,
        COUNT(DISTINCT order_id) AS orders, 
        COUNT(DISTINCT order_id) FILTER(WHERE rank=1) AS first_orders
    FROM
        (SELECT 
            user_id, 
            time, 
            order_id,
            ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY time) as rank,
            MIN(time) OVER(PARTITION BY user_id) AS first_time
        FROM user_actions
        WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
        AND action='create_order') t
    GROUP BY time::DATE
    ORDER BY date
), new_users_orders AS (
    SELECT 
        time::DATE as date,
        COUNT(DISTINCT order_id),
        COUNT(DISTINCT order_id) FILTER(WHERE time::DATE = first_time::DATE) AS new_users_orders
    FROM
        (SELECT 
            user_id, 
            time, 
            order_id,
            MIN(time) OVER(PARTITION BY user_id) AS first_time
        FROM user_actions
        WHERE action='create_order') t
    WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
    GROUP BY time::DATE
    ORDER BY date
)

SELECT 
    date, 
    orders, 
    first_orders, 
    new_users_orders,
    ROUND((100*first_orders::DECIMAL/orders), 2) AS first_orders_share,
    ROUND((100*new_users_orders::DECIMAL/orders), 2) AS new_users_orders_share
FROM first_total_orders
LEFT JOIN new_users_orders USING(date)
ORDER BY date










