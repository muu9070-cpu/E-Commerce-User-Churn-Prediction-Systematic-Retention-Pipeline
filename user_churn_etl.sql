USE taobao_analysis;
SELECT * FROM taobao_analysis.user_churn_features;

DROP TABLE IF EXISTS user_churn_features;

CREATE TABLE user_churn_features AS
WITH base_features AS (
    SELECT 
        user_id,
        
        (1512229199 - MAX(CASE WHEN timestamp <= 1512229199 THEN timestamp END)) / 3600 AS recency_hours,
        
     
        COUNT(CASE WHEN behavior_type = 'pv' AND timestamp <= 1512229199 THEN 1 END) AS pv_count_8d,
        COUNT(CASE WHEN behavior_type = 'fav' AND timestamp <= 1512229199 THEN 1 END) AS fav_count_8d,
        COUNT(CASE WHEN behavior_type = 'cart' AND timestamp <= 1512229199 THEN 1 END) AS cart_count_8d,
        COUNT(CASE WHEN behavior_type = 'buy' AND timestamp <= 1512229199 THEN 1 END) AS buy_count_8d,
        
       
        CASE WHEN COUNT(CASE WHEN behavior_type IN ('cart', 'buy') AND timestamp > 1512229199 THEN 1 END) = 0 THEN 1 ELSE 0 END AS is_churn
    FROM user_behavior
    GROUP BY user_id
)
SELECT 
    user_id,
    COALESCE(recency_hours, 192) AS recency_hours, 
    pv_count_8d,
    fav_count_8d,
    cart_count_8d,
    buy_count_8d,
    CASE WHEN pv_count_8d > 0 THEN buy_count_8d / pv_count_8d ELSE 0 END AS pv_to_buy_ratio,
    is_churn
FROM base_features
WHERE pv_count_8d > 0 OR cart_count_8d > 0;

SELECT COUNT(*) AS total_users, SUM(is_churn) AS churn_users FROM user_churn_features;

