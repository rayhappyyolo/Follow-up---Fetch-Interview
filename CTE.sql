USE fetch_analysis;
CREATE TABLE customer_transactions (
    customer_id VARCHAR(10),
    transaction_date DATE,
    dollar DECIMAL(10, 2),
    product_category VARCHAR(50),
    location VARCHAR(50),
    receipt_status ENUM('Processed', 'Pending', 'Failed')
);

WITH customer_sales AS (
    SELECT 
        customer_id, 
        AVG(dollar) AS average_spent,
        CASE 
            WHEN EXTRACT(YEAR FROM transaction_date) = 2023 THEN 'previous'
            WHEN EXTRACT(YEAR FROM transaction_date) = 2024 THEN 'recent'
        END AS period
    FROM customer_transactions
    GROUP BY customer_id, period
),
-- Calculates the average spending for each customer by year. Labels 2023 as "previous" and 2024 as "recent."
best_customers AS (
    SELECT 
        customer_id, 
        MAX(average_spent) AS max_average_spent
    FROM customer_sales
    WHERE period = 'previous'
    GROUP BY customer_id
    HAVING MAX(average_spent) >= 100
),
-- Identifies "best customers" who spent at least $100 in 2023.
customer_trends AS (
    SELECT 
        cs.customer_id,
        cs.period,
        COALESCE(cs.average_spent, 0) AS average_spent,                      
        COALESCE(LAG(cs.average_spent) 
        OVER (PARTITION BY cs.customer_id ORDER BY cs.period), 0) 
        AS previous_period_average_spent
    FROM customer_sales cs
    JOIN best_customers bc ON cs.customer_id = bc.customer_id
)
-- Includes all "best customers" and their spending trends across years. If a year is missing, average_spent is set to 0.
SELECT 
    customer_id,
    period,
    average_spent,
    previous_period_average_spent,
    (average_spent - previous_period_average_spent) AS average_spent_change
FROM customer_trends
WHERE period = 'recent'
ORDER BY average_spent_change DESC;
-- Retrieves the most recent spending data and compares it to the previous year, calculating the spending change.