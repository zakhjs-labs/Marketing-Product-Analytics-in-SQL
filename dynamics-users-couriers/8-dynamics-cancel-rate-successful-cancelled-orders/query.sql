WITH canceled_orders AS (
  SELECT order_id FROM user_actions
  WHERE action='cancel_order'
),
total_orders_t AS (
  SELECT DATE_PART('hour', time) as hour,
  COUNT(order_id) as total_orders
  FROM user_actions
  WHERE action='create_order'
  GROUP BY hour
),
success_orders_t AS (
  SELECT DATE_PART('hour', time) as hour,
  COUNT(order_id) as successful_orders
  FROM user_actions
  WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
  GROUP BY hour
)

SELECT t1.hour::INTEGER, successful_orders, (total_orders - successful_orders) as canceled_orders,
ROUND(((total_orders - successful_orders)::DECIMAL/total_orders),3) as cancel_rate
FROM success_orders_t t1
LEFT JOIN total_orders_t t2 USING(hour)
ORDER BY hour