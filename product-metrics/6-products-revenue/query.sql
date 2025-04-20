WITH canceled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
),

extract_orders AS (
    SELECT
        creation_time::date AS date,
        order_id,
        unnest(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (
        SELECT order_id
        FROM canceled_orders
    )
),

product_revenue AS (
    SELECT
        product_id,
        name AS product_name,
        SUM(price) AS revenue,
        SUM(SUM(price)) OVER () AS total_revenue,
        ROUND(100 * (SUM(price) / SUM(SUM(price)) OVER ()), 2) AS share_in_revenue
    FROM extract_orders t1
    LEFT JOIN products t2 USING (product_id)
    GROUP BY product_id, name
),

new_other_group AS (
    SELECT
        revenue,
        share_in_revenue,
        CASE
            WHEN share_in_revenue < 0.5 THEN 'ДРУГОЕ'
            ELSE product_name
        END AS product_name
    FROM product_revenue
)

SELECT
    product_name,
    SUM(revenue) AS revenue,
    SUM(share_in_revenue) AS share_in_revenue
FROM new_other_group
GROUP BY product_name
ORDER BY revenue DESC;
