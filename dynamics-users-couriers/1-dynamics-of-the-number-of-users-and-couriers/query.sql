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
)

SELECT date, nu.new_users, nc.new_couriers,
SUM(nu.new_users) OVER(ORDER BY date)::INTEGER AS total_users,
SUM(nc.new_couriers) OVER(ORDER BY date)::INTEGER AS total_couriers
FROM t1 nu
FULL JOIN t2 nc USING(date)
ORDER BY date