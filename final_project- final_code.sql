WITH monthly_revenue AS (
    SELECT
        DATE(DATE_TRUNC('month', payment_date)) AS payment_month, 													-- Цей рядок визначає місяць платежу, округляючи дату до початку місяця.
        user_id,
        game_name,
        SUM(revenue_amount_usd) AS total_revenue 																	-- Це розрахунок суми доходу (MRR).
    FROM project.games_payments
    GROUP BY payment_month, user_id, game_name
),
revenue_lag_lead_months AS (
    SELECT
        mr.*,
        DATE(LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month)) AS previous_calendar_month, 	-- Цей рядок визначає попередній календарний місяць для кожного користувача.
        DATE(payment_month + INTERVAL '1 month') AS next_calendar_month, 											-- Цей рядок визначає наступний календарний місяць для кожного платежу.
        LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_paid_month_revenue, 		-- Цей рядок знаходить дохід користувача за попередній платіжний місяць.
        LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS previous_paid_month, 				-- Цей рядок визначає попередній місяць, у якому був платіж.
        LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS next_paid_month, 					-- Цей рядок знаходить наступний місяць, у якому був платіж.
        MIN(payment_month) OVER (PARTITION BY user_id) AS first_payment_month 										-- Цей рядок визначає перший місяць платежу користувача.
    FROM monthly_revenue mr
),
revenue_metrics AS (
    SELECT
        rlm.payment_month,
        rlm.user_id,
        rlm.game_name,
        rlm.total_revenue,
        rlm.first_payment_month, 
        CASE 
            WHEN rlm.previous_paid_month IS NULL THEN rlm.total_revenue 											-- Цей рядок розраховує дохід від нових користувачів, якщо у них немає попереднього платежу.
            ELSE 0
        END AS new_mrr,
        CASE 
            WHEN rlm.previous_paid_month_revenue < rlm.total_revenue 
            THEN rlm.total_revenue - rlm.previous_paid_month_revenue 												-- Цей рядок визначає розширення доходу, якщо дохід цього місяця більший за попередній.
            ELSE 0
        END AS expansion_revenue,
        CASE 
            WHEN rlm.previous_paid_month_revenue > rlm.total_revenue 
            THEN rlm.previous_paid_month_revenue - rlm.total_revenue 												-- Цей рядок визначає скорочення доходу, якщо дохід цього місяця менший за попередній.
            ELSE 0
        END AS contraction_revenue,
        CASE 
            WHEN rlm.next_paid_month IS NULL THEN rlm.total_revenue 												-- Цей рядок визначає дохід, який втрачається через відпадання користувачів.
            ELSE 0
        END AS churned_revenue,
        CASE 
            WHEN rlm.next_paid_month IS NULL THEN 1 																-- Цей рядок визначає, чи користувач став churned у цьому місяці.
            ELSE 0
        END AS churn_users,
        CASE
            WHEN rlm.next_paid_month IS NULL
            OR rlm.next_paid_month != rlm.next_calendar_month
                THEN rlm.next_calendar_month 																		-- Цей рядок визначає місяць, у якому користувач став churned.
        END AS churn_month,
        rlm.previous_calendar_month,
        rlm.previous_paid_month,
        rlm.next_paid_month
    FROM revenue_lag_lead_months rlm
)
SELECT
    rm.payment_month,
    rm.user_id,
    rm.game_name,
    rm.total_revenue,
    rm.first_payment_month,
    rm.new_mrr,
    rm.expansion_revenue,
    rm.contraction_revenue,
    rm.churned_revenue,
    rm.churn_users,
    rm.churn_month,
    rm.previous_calendar_month,
    rm.previous_paid_month,
    rm.next_paid_month,
    gpu.language,
    gpu.has_older_device_model,
    gpu.age
FROM revenue_metrics rm
LEFT JOIN project.games_paid_users gpu USING (user_id)																-- Цей рядок додає таблицю з метриками для фільтрів.
ORDER BY rm.payment_month, rm.user_id;
