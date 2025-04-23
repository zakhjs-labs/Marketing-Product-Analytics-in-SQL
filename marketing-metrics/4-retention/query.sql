WITH first_active_date AS (
    SELECT 
        user_id,
        time::DATE as dt,
        order_id,
        MIN(time::DATE) OVER(PARTITION BY user_id) AS init_date
    FROM user_actions
)

SELECT 
    init_date, 
    dt, 
    COUNT(DISTINCT user_id) AS active_users,
    (COUNT(DISTINCT user_id)::DECIMAL/MAX(COUNT(DISTINCT user_id)) OVER(PARTITION BY init_date)) AS active_users_share,
    DATE_TRUNC('month', dt) AS active_month,
    DATE_TRUNC('month', init_date) AS month,
    (dt-init_date) AS day_number,
    CONCAT(TO_CHAR(dt, 'YYYY'), ' ', (TO_CHAR(dt, 'Month'))) AS active_month_by_char,
    CONCAT(TO_CHAR(init_date, 'YYYY'), ' ', (TO_CHAR(init_date, 'Month'))) AS month_by_char
FROM first_active_date
GROUP BY init_date, dt 
ORDER BY init_date, dt
