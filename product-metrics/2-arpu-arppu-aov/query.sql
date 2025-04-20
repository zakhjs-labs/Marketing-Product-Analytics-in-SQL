WITH canceled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action='cancel_order'
), revenue_and_orders AS (
    SELECT creation_time::DATE as date, SUM(price) as revenue, COUNT(DISTINCT order_id) as orders_count
    FROM 
        (SELECT creation_time, order_id, unnest(product_ids) as product_id
        FROM orders
        WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)) t1
    LEFT JOIN products p USING(product_id)
    GROUP BY creation_time::DATE
), cat_users AS (
    SELECT 
        time::DATE as date,
        COUNT(DISTINCT user_id) FILTER (WHERE order_id NOT IN (SELECT order_id FROM canceled_orders) AND action = 'create_order') AS paying_users,
        COUNT(DISTINCT user_id) AS users
    FROM user_actions 
    GROUP BY time::DATE
)

SELECT 
    ro.date,
    ROUND(revenue::DECIMAL/users, 2) AS arpu,
    ROUND(revenue::DECIMAL/paying_users, 2) AS arppu,
    ROUND(revenue::DECIMAL/orders_count, 2) AS aov
FROM revenue_and_orders ro
LEFT JOIN cat_users cu ON ro.date = cu.date
