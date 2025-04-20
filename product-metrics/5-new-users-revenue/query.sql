WITH canceled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
),

extract_orders AS (
    SELECT
        creation_time::DATE AS date,
        order_id,
        unnest(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (
        SELECT order_id
        FROM canceled_orders
    )
),

orders_price AS (
    SELECT
        date,
        order_id,
        user_id,
        order_price
    FROM (
        SELECT
            date,
            order_id,
            SUM(price) AS order_price
        FROM extract_orders t1
        LEFT JOIN products t2 USING (product_id)
        GROUP BY date, order_id
    ) t1
    LEFT JOIN user_actions t2 USING (order_id)
),

rev_per_day AS (
    SELECT
        date,
        SUM(order_price) AS revenue
    FROM orders_price
    GROUP BY date
),

new_users_date AS (
    SELECT
        user_id,
        MIN(time)::DATE AS date
    FROM user_actions
    GROUP BY user_id
),

new_users_rev AS (
    SELECT
        date,
        SUM(order_price) AS new_users_revenue
    FROM new_users_date
    LEFT JOIN orders_price USING (user_id, date)
    GROUP BY date
)

SELECT
    t1.date,
    revenue,
    new_users_revenue,
    ROUND(100 * (new_users_revenue::DECIMAL / revenue), 2) AS new_users_revenue_share,
    ROUND(100 - (100 * (new_users_revenue::DECIMAL / revenue)), 2) AS old_users_revenue_share
FROM rev_per_day t1
LEFT JOIN new_users_rev t2 USING (date)
ORDER BY date ASC;
