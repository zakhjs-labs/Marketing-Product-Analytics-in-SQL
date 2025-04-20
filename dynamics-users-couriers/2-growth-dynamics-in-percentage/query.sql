WITH t1 AS (
    SELECT date, COUNT(DISTINCT user_id) AS new_users
    FROM
        (SELECT time::DATE as date, user_id, 
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY time) as rn
        FROM user_actions) t
    WHERE rn = 1
    GROUP BY date
), t2 AS (
    SELECT date, COUNT(courier_id) AS new_couriers
    FROM
        (SELECT courier_id, MIN(time)::DATE as date
        FROM courier_actions
        GROUP BY courier_id) t
    GROUP BY date
), users_couriers_dyn AS (
    SELECT date, nu.new_users, nc.new_couriers,
    SUM(nu.new_users) OVER(ORDER BY date)::INTEGER AS total_users,
    SUM(nc.new_couriers) OVER(ORDER BY date)::INTEGER AS total_couriers
    FROM t1 nu
    FULL JOIN t2 nc USING(date)
    ORDER BY date
)
SELECT date, new_users, new_couriers, total_users, total_couriers,
ROUND(100*(new_users - LAG(new_users, 1) OVER(ORDER BY date)::DECIMAL)/LAG(new_users, 1) OVER(ORDER BY date), 2) as new_users_change,
ROUND(100*(new_couriers - LAG(new_couriers, 1) OVER(ORDER BY date)::DECIMAL)/LAG(new_couriers, 1) OVER(ORDER BY date), 2) as new_couriers_change,
ROUND(100*(total_users - LAG(total_users, 1) OVER(ORDER BY date)::DECIMAL)/LAG(total_users, 1) OVER(ORDER BY date), 2) as total_users_growth,
ROUND(100*(total_couriers - LAG(total_couriers, 1) OVER(ORDER BY date)::DECIMAL)/LAG(total_couriers, 1) OVER(ORDER BY date), 2) as total_couriers_growth
FROM users_couriers_dyn
ORDER BY date


