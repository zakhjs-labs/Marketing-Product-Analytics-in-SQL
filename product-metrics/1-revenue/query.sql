WITH canceled_orders AS (
    SELECT order_id
    FROM user_actions
    WHERE action='cancel_order'
), rev AS (
    SELECT creation_time::DATE as date, SUM(price) as revenue
    FROM 
        (SELECT creation_time, order_id, unnest(product_ids) as product_id
        FROM orders
        WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)) t1
    LEFT JOIN products p USING(product_id)
    GROUP BY creation_time::DATE
)

SELECT 
    date,
    revenue,
    SUM(revenue) OVER(ORDER BY date) AS total_revenue,
    ROUND(100*(revenue - LAG(revenue, 1) OVER(ORDER BY date))::DECIMAL/LAG(revenue, 1) OVER(ORDER BY date), 2) AS revenue_change
FROM rev
ORDER BY date
