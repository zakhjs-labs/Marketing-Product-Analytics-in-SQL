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
),

daily_revenue AS (
    SELECT 
        creation_time::date AS date,
        COUNT(DISTINCT order_id) AS orders,
        SUM(price) AS revenue
    FROM order_products
    LEFT JOIN products USING (product_id)
    GROUP BY date
),
-- уже не нужно
daily_users AS (
    SELECT 
        time::date AS date,
        COUNT(DISTINCT user_id) AS users
    FROM user_actions
    GROUP BY date
),
-- тоже не нужно
daily_paying_users AS (
    SELECT 
        time::date AS date,
        COUNT(DISTINCT user_id) AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
    GROUP BY date
),
-- учитываем накопительный
new_users_dates AS (
    SELECT 
        user_id,
        MIN(time::date) AS date
    FROM user_actions
    GROUP BY user_id
),

daily_new_users AS (
    SELECT 
        date,
        COUNT(user_id) AS new_users
    FROM new_users_dates
    GROUP BY date
),

new_paying_users_dates AS (
    SELECT 
        user_id,
        MIN(time::date) AS date
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM cancelled_orders)
    GROUP BY user_id
),

daily_new_paying_users AS (
    SELECT 
        date,
        COUNT(user_id) AS new_paying_users
    FROM new_paying_users_dates
    GROUP BY date
)

SELECT 
    date,
    ROUND(SUM(revenue) OVER (ORDER BY date)::decimal / SUM(new_users) OVER (ORDER BY date), 2) AS running_arpu,
    ROUND(SUM(revenue) OVER (ORDER BY date)::decimal / SUM(new_paying_users) OVER (ORDER BY date), 2) AS running_arppu,
    ROUND(SUM(revenue) OVER (ORDER BY date)::decimal / SUM(orders) OVER (ORDER BY date), 2) AS running_aov
FROM daily_revenue
LEFT JOIN daily_new_users USING (date)
LEFT JOIN daily_new_paying_users USING (date)