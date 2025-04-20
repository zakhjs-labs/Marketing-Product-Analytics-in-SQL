-- Анализ доли активных пользователей и курьеров
WITH canceled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
),

paying_users AS (
    SELECT 
        time::DATE AS date, 
        COUNT(DISTINCT user_id) AS paying_users
    FROM user_actions
    WHERE 
        order_id NOT IN (SELECT order_id FROM canceled_orders)
        AND action = 'create_order'
    GROUP BY time::DATE
),

active_couriers AS (
    SELECT 
        time::DATE AS date, 
        COUNT(DISTINCT courier_id) AS active_couriers
    FROM courier_actions
    WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
    GROUP BY time::DATE
),

new_users AS (
    SELECT 
        date,
        COUNT(DISTINCT user_id) AS new_users,
        SUM(COUNT(DISTINCT user_id)) OVER (ORDER BY date)::INTEGER AS total_users
    FROM (
        SELECT 
            user_id, 
            MIN(time)::DATE AS date
        FROM user_actions
        GROUP BY user_id
    ) t
    GROUP BY date
),

new_couriers AS (
    SELECT 
        date,
        COUNT(DISTINCT courier_id) AS new_couriers,
        SUM(COUNT(DISTINCT courier_id)) OVER (ORDER BY date)::INTEGER AS total_couriers
    FROM (
        SELECT 
            courier_id, 
            MIN(time)::DATE AS date
        FROM courier_actions
        GROUP BY courier_id
    ) t
    GROUP BY date
)

SELECT 
    pu.date,
    paying_users,
    active_couriers,
    ROUND(100 * (paying_users::DECIMAL / total_users), 2) AS paying_users_share,
    ROUND(100 * (active_couriers::DECIMAL / total_couriers), 2) AS active_couriers_share
FROM paying_users pu
LEFT JOIN active_couriers ac ON pu.date = ac.date
LEFT JOIN new_users nu ON pu.date = nu.date
LEFT JOIN new_couriers nc ON pu.date = nc.date
ORDER BY pu.date;
