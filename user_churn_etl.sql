USE taobao_analysis;
SELECT * FROM taobao_analysis.user_churn_features;
-- 1. 删掉旧表
DROP TABLE IF EXISTS user_churn_features;

-- 2. 重新用高敏感度、平衡标签逻辑构建特征工程表
CREATE TABLE user_churn_features AS
WITH base_features AS (
    SELECT 
        user_id,
        -- 【特征 1】Recency：截至 12-02 23:59:59，用户最后一次互动过去的时间（小时数）
        (1512229199 - MAX(CASE WHEN timestamp <= 1512229199 THEN timestamp END)) / 3600 AS recency_hours,
        
        -- 【特征 2-5】Frequency：用户在前 8 天内的各行为触发频次（11-25 至 12-02）
        COUNT(CASE WHEN behavior_type = 'pv' AND timestamp <= 1512229199 THEN 1 END) AS pv_count_8d,
        COUNT(CASE WHEN behavior_type = 'fav' AND timestamp <= 1512229199 THEN 1 END) AS fav_count_8d,
        COUNT(CASE WHEN behavior_type = 'cart' AND timestamp <= 1512229199 THEN 1 END) AS cart_count_8d,
        COUNT(CASE WHEN behavior_type = 'buy' AND timestamp <= 1512229199 THEN 1 END) AS buy_count_8d,
        
        -- 【标签 Label 修正】如果在最后 1 天 (12-03 发生于时间戳 > 1512229199)，
        -- 用户没有执行核心转化行为 (cart 或 buy)，则标记为高危流失倾向用户(1)，否则为健康留存用户(0)
        CASE WHEN COUNT(CASE WHEN behavior_type IN ('cart', 'buy') AND timestamp > 1512229199 THEN 1 END) = 0 THEN 1 ELSE 0 END AS is_churn
    FROM user_behavior
    GROUP BY user_id
)
SELECT 
    user_id,
    COALESCE(recency_hours, 192) AS recency_hours, -- 最大惩罚值 8天=192小时
    pv_count_8d,
    fav_count_8d,
    cart_count_8d,
    buy_count_8d,
    CASE WHEN pv_count_8d > 0 THEN buy_count_8d / pv_count_8d ELSE 0 END AS pv_to_buy_ratio,
    is_churn
FROM base_features
WHERE pv_count_8d > 0 OR cart_count_8d > 0;

-- 3. 【核心验证】再次检查特征大表的样本分布
SELECT COUNT(*) AS total_users, SUM(is_churn) AS churn_users FROM user_churn_features;
