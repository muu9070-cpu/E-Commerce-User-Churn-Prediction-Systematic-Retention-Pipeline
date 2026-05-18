# E-Commerce User Churn Prediction & Systematic Retention Pipeline

An end-to-end data science and data engineering project leveraging user behavior dynamics to pre-emptively mitigate customer churn, optimize user retention lifecycle, and deliver quantifiable GMV growth. This repository establishes a systematic, data-driven pipeline utilizing automated **MySQL sliding-window feature engineering**, white-box **Random Forest classification**, and a segmented **actionable voucher incentive framework** with a mathematical ROI formulation.

---

## 📌 1. Business Decomposition & Metric Architecture

* **Business Pain Point**: Acquiring new traffic (Customer Acquisition Cost - CAC) in highly competitive e-commerce environments is drastically more expensive than retaining existing cohorts. Standard retrospective descriptive analysis only identifies users after they have permanently defected. This project builds a **forward-looking early-warning system** to identify high-risk, high-value users prior to churn, allowing targeted marketing intervention.
* **Operational Churn Definition**: Given the high-frequency nature of user-platform interactions, a consumer is defined as exhibiting **High-Risk Churn Propensity (`is_churn = 1`)** if they fail to execute deep, high-intent transactional or consideration actions—specifically **Carting (`cart`)** or **Purchasing (`buy`)**—within a designated 1-day observation window, following an active 8-day engagement window.
* **Feature Engineering Taxonomy**:
  * **Target Variable (Y)**: `is_churn` (1 = Churn Risk / Drop in Engagement, 0 = Healthy Retention).
  * **Recency Feature (X1)**: `recency_hours` — The exact duration (in hours) elapsed between the user's final platform interaction and the cutoff boundary of the feature generation window. This serves as the primary velocity indicator of user disengagement.
  * **Frequency Features (X2 - X5)**: `pv_count_8d`, `fav_count_8d`, `cart_count_8d`, `buy_count_8d` — Absolute aggregated behavior volumes over an 8-day rolling sliding window, measuring absolute affinity.
  * **Derived Micro-Conversion Feature (X6)**: `pv_to_buy_ratio` — The systemic transition rate from broad impression viewing to deterministic acquisition, tracking user purchasing friction.

---

## 🛠️ 2. Production SQL ETL & Sliding-Window Engineering

* **Data Governance & Imbalance Mitigation**: Financial and transaction log data natively suffer from temporal overlap and extreme data imbalance if the observation window is improperly calibrated. An elegant SQL pipeline was designed to structure raw user streams into an analytical feature wide table using Common Table Expressions (CTEs) and UNIX timestamp boundaries. 
* **Data Scale & Label Distribution**: The script successfully extracted **654** total active profiles, capturing a robustly balanced distribution of **357** high-risk churn instances, completely eliminating the hazard of zero-variance model convergence.
* **Feature Extraction Pipeline (`user_churn_etl.sql`)**:
  ```sql
  USE taobao_analysis;

  CREATE TABLE user_churn_features AS
  WITH base_features AS (
      SELECT 
          user_id,
          -- [Recency] Hours elapsed since user's last interaction relative to feature window boundary (2017-12-02 23:59:59)
          (1512229199 - MAX(CASE WHEN timestamp <= 1512229199 THEN timestamp END)) / 3600 AS recency_hours,
          
          -- [Frequency] Behavior aggregations across the 8-day feature generation window
          COUNT(CASE WHEN behavior_type = 'pv' AND timestamp <= 1512229199 THEN 1 END) AS pv_count_8d,
          COUNT(CASE WHEN behavior_type = 'fav' AND timestamp <= 1512229199 THEN 1 END) AS fav_count_8d,
          COUNT(CASE WHEN behavior_type = 'cart' AND timestamp <= 1512229199 THEN 1 END) AS cart_count_8d,
          COUNT(CASE WHEN behavior_type = 'buy' AND timestamp <= 1512229199 THEN 1 END) AS buy_count_8d,
          
          -- [Labeling] High-risk flag: 1 if no deep intent actions (cart/buy) occur in the subsequent 1-day observation window
          CASE WHEN COUNT(CASE WHEN behavior_type IN ('cart', 'buy') AND timestamp > 1512229199 THEN 1 END) = 0 THEN 1 ELSE 0 END AS is_churn
      FROM user_behavior
      GROUP BY user_id
  )
  SELECT 
      user_id,
      COALESCE(recency_hours, 192) AS recency_hours, -- Penalty max value: 8 days = 192 hours
      pv_count_8d,
      fav_count_8d,
      cart_count_8d,
      buy_count_8d,
      CASE WHEN pv_count_8d > 0 THEN buy_count_8d / pv_count_8d ELSE 0 END AS pv_to_buy_ratio,
      is_churn

  ---

## 📊 3. White-Box Modeling & Asymmetric Cost Optimization

The analytical framework implements a robust **Random Forest Classifier** optimized for business-cost utility rather than raw accuracy.

* **Model Evaluation Metrics & Outcomes**:
  * **Asymmetric Risk Strategy**: To align with business realities where a False Negative (leaking an executive active user) costs 10x more than a False Positive (distributing an unnecessary micro-voucher), the classification threshold was tuned down to **0.40**.
  * **Empirical Results**: The system successfully achieved an outstanding **Recall rate of 94.4%** (68 out of 72 true risk vectors accurately detected), capturing critical platform assets before final detachment.
* **Feature Attribution & Information Gain**:
  * Behavioral analysis explicitly identifies `cart_count_8d` as the dominant predictor (Information Gain > 32%). This indicates that strong consideration signals (carting actions) combined with immediate drop-offs provide the most definitive churn signals, far outperforming passive viewing (`pv_count_8d`) or historical purchases (`buy_count_8d`).

---

## 🚀 4. Actionable Multi-Tier Retention Matrix & GMV Quantifiable Lift

The machine learning predictions directly feed into an automated, cross-functional marketing and product operation matrix:

### 💡 Segmented Strategy Lifecycle Matrix
By plotting predicted Churn Probability ($P_{\text{churn}}$) against historical user monetization weight ($M_{\text{volume}}$), the platform triggers targeted webhook events:

| Strategic Segment | Churn Risk Threshold | Historical Value Tier | Operational Playbook (Actionable Advice) |
| :--- | :--- | :--- | :--- |
| **High-Value / High-Risk** | $P_{\text{churn}} \ge 80\%$ | Top 20% GMV Contributors | **Immediate High-Priority Interception**: Trigger push notifications and SMS vectors delivering high-incentive, site-wide premium no-threshold vouchers to shock-activate reactivation. |
| **Mid-Value / High-Risk** | $P_{\text{churn}} \ge 75\%$ | Middle 50% Core Cohort | **Cross-Category Reactivation**: Dynamically inject recommended item modules based on historical category affinity paired with category-specific coupons to stimulate conversion. |
| **Low-Value / High-Risk** | $P_{\text{churn}} \ge 70\%$ | Bottom 30% Low Spenders | **Low-Cost Gamification Engagement**: Route users into low-cost loyalty programs, daily check-in mechanics, or push community content to recover attention without eroding margin. |

### 📈 Quantifiable GMV Impact Simulation Model
To justify the economic viability of the data science architecture, the performance is mapped to an algorithmic revenue growth function:

$$\Delta\text{GMV} = N_{\text{target}} \times \text{Recall} \times \Delta\text{Conversion} \times \text{ALV} - \text{Cost}_{\text{vouchers}}$$

* **Production Proof of Concept**: Assuming a cohort of $10,000$ high-risk accounts are processed, a model Recall of $94.4\%$ accurately isolates $9,440$ valid churn vectors.
* **Strategy Execution**: Implementing the high-incentive tiered playbook achieves a modest $10\%$ reactivation conversion rate among targeted users ($944$ successfully retained customers).
* **Net Revenue Contribution**: With an Average Order Value (AOV / ALV) of $150$ RMB, the architecture directly protects and generates **$141,600$ RMB in incremental gross revenue**. Subtracting voucher redemption costs ($\approx 20,000$ RMB), the framework yields a **Net Economic Benefit of $121,600$ RMB, delivering an enterprise ROI of 6.08x**.
  FROM base_features
  WHERE pv_count_8d > 0 OR cart_count_8d > 0;
