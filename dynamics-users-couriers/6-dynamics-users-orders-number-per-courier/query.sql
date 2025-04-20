WITH canceled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action='cancel_order'
), p_users AS (
    SELECT
        time::DATE as date,
        COUNT(DISTINCT user_id) as paying_users,
        COUNT(DISTINCT order_id) as orders
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
    GROUP BY time::DATE
), a_couriers AS (
    SELECT time::DATE as date, COUNT(DISTINCT courier_id) as active_couriers
    FROM courier_actions
    WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
    GROUP BY time::DATE
)

SELECT
    pu.date,
    ROUND((paying_users::DECIMAL/active_couriers),2) AS users_per_courier,
    ROUND((orders::DECIMAL/active_couriers),2) AS orders_per_courier
FROM p_users pu
LEFT JOIN a_couriers ac ON pu.date = ac.date
ORDER BY pu.date
