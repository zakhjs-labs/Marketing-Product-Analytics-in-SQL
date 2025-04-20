WITH canceled_orders AS (
  SELECT order_id FROM user_actions
  WHERE action = 'cancel_order'
),
extract_orders AS (
  SELECT date, order_id, product_id, price, name
  FROM
      (SELECT creation_time::DATE as date, order_id, unnest(product_ids) as product_id
      FROM orders WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
      ) t1
  LEFT JOIN products t2 USING(product_id)
),
--Выручка, полученная в этот день (ДЛЯ ИТОГОВОЙ ТАБЛИЦЫ)
revenue_per_day AS (
  SELECT date, SUM(price) as revenue
  FROM extract_orders
  GROUP BY date
),
-- Подготовка данных по курьерской доставке
couriers_data AS (
  SELECT time::DATE as date, courier_id, order_id
  FROM courier_actions
  WHERE order_id NOT IN (SELECT order_id FROM canceled_orders)
  AND action='deliver_order'
),
-- Показател количества доставок курьера в определенные даты
couriers_stat AS (
  SELECT date, courier_id, COUNT(DISTINCT order_id) as count_orders
  FROM couriers_data
  GROUP BY date, courier_id
),
-- Расчет затрат на курьеров за доставку + бонус (уже сгруппирован по дате)
cost_per_couriers AS (
  SELECT date, SUM(cost_for_couriers) as cost_for_couriers
  FROM
      (SELECT date, courier_id, count_orders,
        CASE 
        WHEN count_orders >= 5 AND DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 8
        THEN (count_orders*150) + 400
        WHEN count_orders < 5 AND DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 8
        THEN count_orders*150
        WHEN count_orders >= 5 AND DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 9
        THEN (count_orders*150) + 500
        WHEN count_orders < 5 AND DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 9
        THEN count_orders*150
        END AS cost_for_couriers
      FROM couriers_stat) t
  GROUP BY DATE
),
-- Подготовка данных по заказам (количество заказов на день)
orders_count AS (
  SELECT time::DATE as date, COUNT(DISTINCT order_id) as count_orders
  FROM user_actions 
  WHERE action='create_order' AND order_id NOT IN (SELECT order_id FROM canceled_orders)
  GROUP BY date 
),
-- Расчет затран сборку заказов на день
cost_per_orders AS (
  SELECT date,
    CASE
    WHEN DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 8
    THEN count_orders*140
    WHEN DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 9
    THEN count_orders*115 
    END AS cost_for_orders
  FROM orders_count
),
-- Сумма затрат на сборку заказов и на оплату курьерам за доставку (ежедневно)
cost_without_const_t AS (
  SELECT date, cost_for_couriers + cost_for_orders AS cost_without_const
  FROM cost_per_couriers t1
  LEFT JOIN cost_per_orders t2
  USING(date)
  ORDER BY date
), 
-- Общая затрата с учетом затрат на сборку, курьера + постоянные затраты (ДЛЯ ИТОГОВОЙ ТАБЛИЦЫ)
cost_t AS (
  SELECT date,
    CASE
    WHEN DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 8 THEN cost_without_const + 120000
    WHEN DATE_PART('year', date) = 2022 AND DATE_PART('month', date) = 9 THEN cost_without_const + 150000
    ELSE cost_without_const END AS costs
  FROM cost_without_const_t t
  ORDER BY date
),
-- Расчёт величины НДС по каждому (price*10/110 or price*20/120) (ДЛЯ ИТОГОВОЙ ТАБЛИЦЫ)
tax_t AS (
  SELECT date, ROUND(SUM(tax),2) as tax
  FROM
      (SELECT date,
      CASE
      WHEN name IN ('сахар', 'сухарики', 'сушки', 'семечки', 
      'масло льняное', 'виноград', 'масло оливковое', 
      'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
      'овсянка', 'макароны', 'баранина', 'апельсины', 
      'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
      'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
      'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
      'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
      'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины')
      THEN ROUND(price*10/110, 2)
      ELSE ROUND(price*20/120, 2)
      END AS tax
      FROM extract_orders) t
  GROUP BY date
)

SELECT t1.date, revenue, costs, tax,
(revenue - costs - tax) as gross_profit,
SUM(revenue) OVER(ORDER BY date) as total_revenue,
SUM(costs) OVER(ORDER BY date) as total_costs,
SUM(tax) OVER(ORDER BY date) as total_tax,
SUM(revenue - costs - tax) OVER(ORDER BY date) as total_gross_profit,
ROUND(100*(revenue - costs - tax)/revenue, 2) as gross_profit_ratio,
ROUND(100*(SUM(revenue - costs - tax) OVER(ORDER BY date))/(SUM(revenue) OVER(ORDER BY date)), 2) as total_gross_profit_ratio
FROM revenue_per_day t1
LEFT JOIN cost_t t2 USING (date)
LEFT JOIN tax_t t3 USING (date)