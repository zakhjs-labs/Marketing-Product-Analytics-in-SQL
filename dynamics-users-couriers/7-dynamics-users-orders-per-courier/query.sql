SELECT end_time::DATE as date, AVG(deliver_time)::INTEGER as minutes_to_deliver
FROM
    (SELECT MIN(time) as init_time,
    MAX(time) as end_time,
    (EXTRACT(epoch FROM AGE(MAX(time), MIN(time) ))/60)::INTEGER as deliver_time
    FROM courier_actions
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action='cancel_order')
    GROUP BY order_id) t1
GROUP BY date
ORDER BY date 