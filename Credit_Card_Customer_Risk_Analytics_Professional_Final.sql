/*
CREDIT CARD CUSTOMER & RISK ANALYTICS
End-to-end SQL analysis
*/

/*
===============================================================================
PROJECT WORKFLOW
===============================================================================

01. Source Layer
    Load customer, card, transaction, payment and statement source data.

02. Data Quality
    Validate record counts, uniqueness, mandatory fields, financial values and
    key relationships before transformation.

03. Standardization
    Clean source attributes, normalize business labels and convert fields into
    analysis-ready data types.

04. Business Features
    Create age groups, income segments, transaction categories, statement
    months and credit-utilization measures.

05. Performance Structure
    Add the indexes required for recurring joins and reporting queries.

06. Customer & Card Profile
    Analyze customer demographics, income segments and card-product mix.

07. Transaction Performance
    Measure transaction volume, approval rate, spending and customer activity.

08. Customer Value
    Identify high-value customers and rank customers by spending.

09. Credit Utilization & Exposure
    Measure utilization and identify customers with elevated credit exposure.

10. Payment & Delinquency
    Analyze payment performance, outstanding balances and overdue statements.

11. Risk Classification
    Combine utilization and payment behaviour into an analytical risk view.

12. Customer Segmentation
    Classify customers using value, engagement, utilization and risk indicators.

13. Trend Analysis
    Measure monthly spending movement and month-over-month growth.

14. Product & Customer Ranking
    Compare customer performance within card-product groups.

15. Anomaly Screening
    Identify unusually large approved transactions for investigation.

16. Customer 360
    Consolidate customer, card, transaction, payment and risk metrics into a
    reporting-ready analytical view.

17. Executive Reporting
    Produce portfolio KPIs, segment performance and actionable customer
    populations for management reporting.

18. Project Outcome
    Summarize the analytical results, challenges and recommended reporting
    direction.

===============================================================================
*/

USE credit_card_analytics;


/* 01 | SOURCE LAYER
   Preserve source values and load the five operational datasets. */

/* This resets the raw customer staging table before the source load. */
DROP TABLE IF EXISTS raw_customers;
/* This creates the raw customer staging structure for source customer data. */
CREATE TABLE raw_customers (
    customer_id VARCHAR(30),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender VARCHAR(30),
    age VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(100),
    income VARCHAR(50),
    employment_type VARCHAR(100),
    marital_status VARCHAR(50),
    joining_date VARCHAR(50)
);

/* This resets the raw card staging table before the source load. */
DROP TABLE IF EXISTS raw_credit_cards;
/* This creates the raw card staging structure for source credit-card data. */
CREATE TABLE raw_credit_cards (
    card_id VARCHAR(30),
    customer_id VARCHAR(30),
    card_type VARCHAR(50),
    credit_limit VARCHAR(50),
    annual_fee VARCHAR(50),
    issue_date VARCHAR(50),
    status VARCHAR(30)
);

/* This resets the raw transaction staging table before the source load. */
DROP TABLE IF EXISTS raw_transactions;
/* This creates the raw transaction staging structure for source transaction data. */
CREATE TABLE raw_transactions (
    transaction_id VARCHAR(30),
    customer_id VARCHAR(30),
    card_id VARCHAR(30),
    transaction_date VARCHAR(50),
    merchant_category VARCHAR(100),
    transaction_amount VARCHAR(50),
    transaction_type VARCHAR(50),
    payment_mode VARCHAR(50),
    transaction_status VARCHAR(50),
    city VARCHAR(100)
);

/* This resets the raw payment staging table before the source load. */
DROP TABLE IF EXISTS raw_payments;
/* This creates the raw payment staging structure for source payment data. */
CREATE TABLE raw_payments (
    payment_id VARCHAR(30),
    customer_id VARCHAR(30),
    card_id VARCHAR(30),
    payment_date VARCHAR(50),
    payment_amount VARCHAR(50),
    payment_status VARCHAR(50),
    payment_type VARCHAR(50)
);

/* This resets the raw statement staging table before the source load. */
DROP TABLE IF EXISTS raw_monthly_statement;
/* This creates the raw statement staging structure for monthly account data. */
CREATE TABLE raw_monthly_statement (
    statement_id VARCHAR(30),
    customer_id VARCHAR(30),
    card_id VARCHAR(30),
    statement_month VARCHAR(50),
    total_spend VARCHAR(50),
    total_payment VARCHAR(50),
    outstanding_amount VARCHAR(50),
    minimum_due VARCHAR(50),
    payment_due_date VARCHAR(50),
    payment_status VARCHAR(50)
);


/* 02 | DATA INGESTION
   Load the source files into the raw layer without applying business logic. */

LOAD DATA LOCAL INFILE 'C:/credit_card_project/data/customers.csv'
INTO TABLE raw_customers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/credit_card_project/data/credit_cards.csv'
INTO TABLE raw_credit_cards
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/credit_card_project/data/transactions.csv'
INTO TABLE raw_transactions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/credit_card_project/data/payments.csv'
INTO TABLE raw_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/credit_card_project/data/monthly_statement.csv'
INTO TABLE raw_monthly_statement
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


/* 03 | SOURCE QUALITY
   Validate uniqueness, mandatory fields, financial ranges and relationships
   before transforming the data. */

SELECT 'raw_customers' AS dataset, COUNT(*) AS rows_loaded FROM raw_customers
UNION ALL
SELECT 'raw_credit_cards', COUNT(*) FROM raw_credit_cards
UNION ALL
SELECT 'raw_transactions', COUNT(*) FROM raw_transactions
UNION ALL
SELECT 'raw_payments', COUNT(*) FROM raw_payments
UNION ALL
SELECT 'raw_monthly_statement', COUNT(*) FROM raw_monthly_statement;

SELECT customer_id, COUNT(*) AS row_count
FROM raw_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT card_id, COUNT(*) AS row_count
FROM raw_credit_cards
GROUP BY card_id
HAVING COUNT(*) > 1;

SELECT transaction_id, COUNT(*) AS row_count
FROM raw_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

SELECT payment_id, COUNT(*) AS row_count
FROM raw_payments
GROUP BY payment_id
HAVING COUNT(*) > 1;

SELECT
    SUM(customer_id IS NULL OR TRIM(customer_id) = '') AS missing_customer_id,
    SUM(age IS NULL OR TRIM(age) = '') AS missing_age,
    SUM(income IS NULL OR TRIM(income) = '') AS missing_income
FROM raw_customers;

SELECT *
FROM raw_customers
WHERE age IS NULL
   OR TRIM(age) = ''
   OR age REGEXP '[^0-9]'
   OR CAST(age AS UNSIGNED) NOT BETWEEN 18 AND 100;

SELECT *
FROM raw_credit_cards
WHERE credit_limit IS NULL
   OR TRIM(credit_limit) = ''
   OR CAST(REPLACE(credit_limit, ',', '') AS DECIMAL(15,2)) <= 0;

SELECT *
FROM raw_transactions
WHERE transaction_amount IS NULL
   OR TRIM(transaction_amount) = ''
   OR CAST(REPLACE(transaction_amount, ',', '') AS DECIMAL(15,2)) < 0;

SELECT DISTINCT cc.customer_id
FROM raw_credit_cards cc
LEFT JOIN raw_customers c ON c.customer_id = cc.customer_id
WHERE c.customer_id IS NULL;

SELECT DISTINCT t.card_id
FROM raw_transactions t
LEFT JOIN raw_credit_cards c ON c.card_id = t.card_id
WHERE c.card_id IS NULL;


/* 04 | STANDARDIZATION
   Convert source strings to analysis-ready types and normalize business labels. */

/* This replaces the customer table with its standardized analytical version. */
DROP TABLE IF EXISTS customers;
/* This creates the standardized customer dimension from the raw source. */
CREATE TABLE customers AS
SELECT
    TRIM(customer_id) AS customer_id,
    TRIM(first_name) AS first_name,
    TRIM(last_name) AS last_name,
    CASE
        WHEN LOWER(TRIM(gender)) IN ('m','male') THEN 'Male'
        WHEN LOWER(TRIM(gender)) IN ('f','female') THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    CASE
        WHEN age REGEXP '^[0-9]+$'
             AND CAST(age AS UNSIGNED) BETWEEN 18 AND 100
        THEN CAST(age AS UNSIGNED)
    END AS age,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(TRIM(state), '') AS state,
    CASE
        WHEN REPLACE(TRIM(income), ',', '') REGEXP '^[0-9]+(\\.[0-9]+)?$'
        THEN CAST(REPLACE(TRIM(income), ',', '') AS DECIMAL(15,2))
    END AS income,
    CASE
        WHEN LOWER(TRIM(employment_type)) IN ('salary','salaried','employee')
            THEN 'Salaried'
        WHEN LOWER(TRIM(employment_type)) IN ('self employed','self-employed')
            THEN 'Self-Employed'
        WHEN LOWER(TRIM(employment_type)) IN ('business')
            THEN 'Business'
        WHEN LOWER(TRIM(employment_type)) = 'student'
            THEN 'Student'
        WHEN LOWER(TRIM(employment_type)) = 'retired'
            THEN 'Retired'
        ELSE 'Other'
    END AS employment_type,
    CASE
        WHEN LOWER(TRIM(marital_status)) IN ('married','m') THEN 'Married'
        WHEN LOWER(TRIM(marital_status)) IN ('single','s') THEN 'Single'
        WHEN LOWER(TRIM(marital_status)) IN ('divorced','d') THEN 'Divorced'
        WHEN LOWER(TRIM(marital_status)) IN ('widowed','w') THEN 'Widowed'
        ELSE 'Unknown'
    END AS marital_status,
    COALESCE(
        STR_TO_DATE(TRIM(joining_date), '%Y-%m-%d'),
        STR_TO_DATE(TRIM(joining_date), '%d-%m-%Y')
    ) AS joining_date
FROM raw_customers;

/* This establishes customer_id as the unique key for customer-level analysis. */
ALTER TABLE customers
    ADD PRIMARY KEY (customer_id);

/* This replaces the card table with its standardized analytical version. */
DROP TABLE IF EXISTS credit_cards;
/* This creates the standardized credit-card table from the raw source. */
CREATE TABLE credit_cards AS
SELECT
    TRIM(card_id) AS card_id,
    TRIM(customer_id) AS customer_id,
    CASE
        WHEN LOWER(TRIM(card_type)) = 'platinum' THEN 'Platinum'
        WHEN LOWER(TRIM(card_type)) = 'gold' THEN 'Gold'
        WHEN LOWER(TRIM(card_type)) = 'silver' THEN 'Silver'
        WHEN LOWER(TRIM(card_type)) IN ('classic','standard') THEN 'Classic'
        ELSE 'Other'
    END AS card_type,
    CAST(REPLACE(TRIM(credit_limit), ',', '') AS DECIMAL(15,2)) AS credit_limit,
    COALESCE(
        CAST(REPLACE(TRIM(annual_fee), ',', '') AS DECIMAL(10,2)), 0
    ) AS annual_fee,
    COALESCE(
        STR_TO_DATE(TRIM(issue_date), '%Y-%m-%d'),
        STR_TO_DATE(TRIM(issue_date), '%d-%m-%Y')
    ) AS issue_date,
    CASE
        WHEN LOWER(TRIM(status)) IN ('active','activated') THEN 'Active'
        WHEN LOWER(TRIM(status)) IN ('inactive','closed') THEN 'Inactive'
        WHEN LOWER(TRIM(status)) IN ('blocked','suspended') THEN 'Blocked'
        ELSE 'Unknown'
    END AS status
FROM raw_credit_cards;

/* This establishes card_id as the unique key for card-level analysis. */
ALTER TABLE credit_cards
    ADD PRIMARY KEY (card_id);

/* This replaces the transaction table with its standardized analytical version. */
DROP TABLE IF EXISTS transactions;
/* This creates the standardized transaction fact table from the raw source. */
CREATE TABLE transactions AS
SELECT
    TRIM(transaction_id) AS transaction_id,
    TRIM(customer_id) AS customer_id,
    TRIM(card_id) AS card_id,
    COALESCE(
        STR_TO_DATE(TRIM(transaction_date), '%Y-%m-%d'),
        STR_TO_DATE(TRIM(transaction_date), '%d-%m-%Y')
    ) AS transaction_date,
    TRIM(merchant_category) AS merchant_category,
    CAST(REPLACE(TRIM(transaction_amount), ',', '') AS DECIMAL(15,2))
        AS transaction_amount,
    CASE
        WHEN LOWER(TRIM(transaction_type)) IN ('purchase','buy')
            THEN 'Purchase'
        WHEN LOWER(TRIM(transaction_type)) IN ('refund','return')
            THEN 'Refund'
        WHEN LOWER(TRIM(transaction_type)) IN ('cash withdrawal','cash advance')
            THEN 'Cash Advance'
        ELSE 'Other'
    END AS transaction_type,
    CASE
        WHEN LOWER(TRIM(payment_mode)) IN ('pos','point of sale') THEN 'POS'
        WHEN LOWER(TRIM(payment_mode)) IN ('online','ecommerce','e-commerce')
            THEN 'Online'
        WHEN LOWER(TRIM(payment_mode)) = 'atm' THEN 'ATM'
        ELSE 'Other'
    END AS payment_mode,
    CASE
        WHEN LOWER(TRIM(transaction_status))
             IN ('approved','success','successful') THEN 'Approved'
        WHEN LOWER(TRIM(transaction_status))
             IN ('declined','failed','failure') THEN 'Declined'
        WHEN LOWER(TRIM(transaction_status))
             IN ('reversed','reverse') THEN 'Reversed'
        ELSE 'Unknown'
    END AS transaction_status,
    TRIM(city) AS city
FROM raw_transactions;

/* This establishes transaction_id as the unique transaction key. */
ALTER TABLE transactions
    ADD PRIMARY KEY (transaction_id);

/* This replaces the payment table with its standardized analytical version. */
DROP TABLE IF EXISTS payments;
/* This creates the standardized payment fact table from the raw source. */
CREATE TABLE payments AS
SELECT
    TRIM(payment_id) AS payment_id,
    TRIM(customer_id) AS customer_id,
    TRIM(card_id) AS card_id,
    COALESCE(
        STR_TO_DATE(TRIM(payment_date), '%Y-%m-%d'),
        STR_TO_DATE(TRIM(payment_date), '%d-%m-%Y')
    ) AS payment_date,
    CAST(REPLACE(TRIM(payment_amount), ',', '') AS DECIMAL(15,2))
        AS payment_amount,
    CASE
        WHEN LOWER(TRIM(payment_status))
             IN ('successful','success','completed') THEN 'Successful'
        WHEN LOWER(TRIM(payment_status))
             IN ('failed','failure','declined') THEN 'Failed'
        WHEN LOWER(TRIM(payment_status)) = 'pending' THEN 'Pending'
        ELSE 'Unknown'
    END AS payment_status,
    TRIM(payment_type) AS payment_type
FROM raw_payments;

/* This establishes payment_id as the unique payment key. */
ALTER TABLE payments
    ADD PRIMARY KEY (payment_id);

/* This replaces the statement table with its standardized analytical version. */
DROP TABLE IF EXISTS monthly_statement;
/* This creates the standardized monthly statement table from the raw source. */
CREATE TABLE monthly_statement AS
SELECT
    TRIM(statement_id) AS statement_id,
    TRIM(customer_id) AS customer_id,
    TRIM(card_id) AS card_id,
    COALESCE(
        STR_TO_DATE(TRIM(statement_month), '%Y-%m-%d'),
        STR_TO_DATE(TRIM(statement_month), '%d-%m-%Y')
    ) AS statement_month,
    CAST(REPLACE(TRIM(total_spend), ',', '') AS DECIMAL(15,2))
        AS total_spend,
    CAST(REPLACE(TRIM(total_payment), ',', '') AS DECIMAL(15,2))
        AS total_payment,
    CAST(REPLACE(TRIM(outstanding_amount), ',', '') AS DECIMAL(15,2))
        AS outstanding_amount,
    CAST(REPLACE(TRIM(minimum_due), ',', '') AS DECIMAL(15,2))
        AS minimum_due,
    COALESCE(
        STR_TO_DATE(TRIM(payment_due_date), '%Y-%m-%d'),
        STR_TO_DATE(TRIM(payment_due_date), '%d-%m-%Y')
    ) AS payment_due_date,
    CASE
        WHEN LOWER(TRIM(payment_status))
             IN ('paid','payment made','completed') THEN 'Paid'
        WHEN LOWER(TRIM(payment_status))
             IN ('pending','due','unpaid') THEN 'Pending'
        WHEN LOWER(TRIM(payment_status))
             IN ('overdue','late') THEN 'Overdue'
        ELSE 'Unknown'
    END AS payment_status
FROM raw_monthly_statement;

/* This establishes statement_id as the unique statement key. */
ALTER TABLE monthly_statement
    ADD PRIMARY KEY (statement_id);


/* 05 | BUSINESS FEATURES
   Add reusable dimensions and credit-behaviour measures required for analysis. */

/* This adds reusable customer segmentation attributes for downstream analysis. */
ALTER TABLE customers
    ADD COLUMN age_group VARCHAR(20),
    ADD COLUMN income_segment VARCHAR(30);

/* This populates customer age and income segments using business rules. */
UPDATE customers
SET
    age_group = CASE
        WHEN age IS NULL THEN 'Unknown'
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END,
    income_segment = CASE
        WHEN income IS NULL THEN 'Unknown'
        WHEN income < 300000 THEN 'Low Income'
        WHEN income < 700000 THEN 'Middle Income'
        WHEN income < 1500000 THEN 'High Income'
        ELSE 'Premium'
    END;

/* This adds reporting dimensions required for monthly and category analysis. */
ALTER TABLE transactions
    ADD COLUMN transaction_month DATE,
    ADD COLUMN transaction_category VARCHAR(50);

/* This derives the reporting month and analytical transaction category. */
UPDATE transactions
SET
    transaction_month = DATE_FORMAT(transaction_date, '%Y-%m-01'),
    transaction_category = CASE
        WHEN LOWER(merchant_category) IN ('grocery','supermarket','groceries')
            THEN 'Essential'
        WHEN LOWER(merchant_category) IN ('restaurant','food','dining')
            THEN 'Food'
        WHEN LOWER(merchant_category) IN ('electronics','luxury','jewellery')
            THEN 'Lifestyle'
        WHEN LOWER(merchant_category) IN ('travel','airline','hotel')
            THEN 'Travel'
        WHEN LOWER(merchant_category) IN ('fuel','petrol','gas station')
            THEN 'Fuel'
        WHEN LOWER(merchant_category) IN ('utility','utilities','electricity','telecom')
            THEN 'Utilities'
        ELSE 'Other'
    END;

/* This adds credit-utilization measures derived from outstanding balance and limit. */
ALTER TABLE monthly_statement
    ADD COLUMN utilization_percentage DECIMAL(8,2),
    ADD COLUMN utilization_category VARCHAR(20);

/* This calculates utilization and assigns the corresponding utilization band. */
UPDATE monthly_statement s
JOIN credit_cards c ON c.card_id = s.card_id
SET
    s.utilization_percentage =
        ROUND(s.outstanding_amount / NULLIF(c.credit_limit, 0) * 100, 2),
    s.utilization_category =
        CASE
            WHEN s.outstanding_amount / NULLIF(c.credit_limit, 0) < 0.30
                THEN 'Low'
            WHEN s.outstanding_amount / NULLIF(c.credit_limit, 0) < 0.70
                THEN 'Medium'
            WHEN s.outstanding_amount / NULLIF(c.credit_limit, 0) < 0.90
                THEN 'High'
            ELSE 'Critical'
        END;


/* 06 | PERFORMANCE STRUCTURE
   Index the primary join and reporting paths used by the analytical layer. */

/* This indexes the card-to-customer join used throughout the analysis. */
CREATE INDEX idx_cards_customer
    ON credit_cards(customer_id);

/* This indexes customer-level transaction joins and aggregations. */
CREATE INDEX idx_transactions_customer
    ON transactions(customer_id);

/* This indexes card-level transaction joins used in portfolio analysis. */
CREATE INDEX idx_transactions_card
    ON transactions(card_id);

/* This indexes monthly transaction reporting and trend analysis. */
CREATE INDEX idx_transactions_month
    ON transactions(transaction_month);

/* This indexes customer-level payment analysis. */
CREATE INDEX idx_payments_customer
    ON payments(customer_id);

/* This indexes customer-level statement and risk analysis. */
CREATE INDEX idx_statement_customer
    ON monthly_statement(customer_id);

/* This indexes monthly statement reporting and trend analysis. */
CREATE INDEX idx_statement_month
    ON monthly_statement(statement_month);


/* 07 | CUSTOMER & CARD PROFILE
   Establish the portfolio base and product mix. */

SELECT
    COUNT(*) AS customers,
    COUNT(DISTINCT city) AS cities,
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(income), 2) AS avg_income
FROM customers;

SELECT
    card_type,
    COUNT(*) AS cards,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(credit_limit), 2) AS total_credit_limit,
    ROUND(AVG(credit_limit), 2) AS avg_credit_limit
FROM credit_cards
GROUP BY card_type
ORDER BY total_credit_limit DESC;


/* 08 | TRANSACTION PERFORMANCE
   Measure spend, volume, approval performance and customer activity. */

SELECT
    COUNT(*) AS transactions,
    COUNT(DISTINCT customer_id) AS transacting_customers,
    SUM(transaction_status = 'Approved') AS approved_transactions,
    ROUND(
        SUM(transaction_status = 'Approved') * 100.0 / COUNT(*), 2
    ) AS approval_rate,
    ROUND(
        SUM(CASE WHEN transaction_status = 'Approved'
                 THEN transaction_amount ELSE 0 END), 2
    ) AS approved_spend,
    ROUND(
        AVG(CASE WHEN transaction_status = 'Approved'
                 THEN transaction_amount END), 2
    ) AS avg_approved_transaction
FROM transactions;

SELECT
    transaction_month,
    COUNT(*) AS transactions,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(transaction_amount), 2) AS approved_spend
FROM transactions
WHERE transaction_status = 'Approved'
GROUP BY transaction_month
ORDER BY transaction_month;

SELECT
    transaction_category,
    COUNT(*) AS transactions,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(transaction_amount), 2) AS spend
FROM transactions
WHERE transaction_status = 'Approved'
GROUP BY transaction_category
ORDER BY spend DESC;


/* 09 | CUSTOMER VALUE
   Identify high-value customers and concentration of portfolio spend. */

WITH customer_spend AS (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        SUM(transaction_amount) AS total_spend,
        AVG(transaction_amount) AS avg_transaction
    FROM transactions
    WHERE transaction_status = 'Approved'
    GROUP BY customer_id
)
SELECT
    cs.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.income_segment,
    cs.transaction_count,
    ROUND(cs.total_spend, 2) AS total_spend,
    ROUND(cs.avg_transaction, 2) AS avg_transaction,
    RANK() OVER (ORDER BY cs.total_spend DESC) AS spend_rank
FROM customer_spend cs
JOIN customers c ON c.customer_id = cs.customer_id
ORDER BY spend_rank
LIMIT 25;


/* 10 | CREDIT UTILIZATION & EXPOSURE
   Quantify revolving exposure and identify elevated utilization. */

SELECT
    utilization_category,
    COUNT(*) AS statements,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(AVG(utilization_percentage), 2) AS avg_utilization,
    ROUND(SUM(outstanding_amount), 2) AS outstanding
FROM monthly_statement
GROUP BY utilization_category
ORDER BY avg_utilization DESC;

SELECT
    s.customer_id,
    CONCAT(cu.first_name, ' ', cu.last_name) AS customer_name,
    s.card_id,
    cc.card_type,
    cc.credit_limit,
    s.outstanding_amount,
    s.utilization_percentage,
    s.payment_status
FROM monthly_statement s
JOIN customers cu ON cu.customer_id = s.customer_id
JOIN credit_cards cc ON cc.card_id = s.card_id
WHERE s.utilization_percentage >= 70
ORDER BY s.utilization_percentage DESC, s.outstanding_amount DESC
LIMIT 100;


/* 11 | PAYMENT & DELINQUENCY
   Assess payment reliability and outstanding-risk concentration. */

SELECT
    payment_status,
    COUNT(*) AS statements,
    ROUND(SUM(outstanding_amount), 2) AS outstanding
FROM monthly_statement
GROUP BY payment_status
ORDER BY outstanding DESC;

SELECT
    payment_status,
    COUNT(*) AS payments,
    ROUND(SUM(payment_amount), 2) AS payment_value
FROM payments
GROUP BY payment_status
ORDER BY payment_value DESC;

SELECT
    ROUND(
        SUM(payment_status = 'Successful') * 100.0 / COUNT(*), 2
    ) AS payment_success_rate
FROM payments;


/* 12 | RISK CLASSIFICATION
   Combine utilization and payment behaviour into an analytical risk view. */

/* This recreates the analytical risk table from the latest statement data. */
DROP TABLE IF EXISTS customer_risk;

/* This creates a customer-level risk dataset from utilization and payment behaviour. */
CREATE TABLE customer_risk AS
SELECT
    s.customer_id,
    s.card_id,
    s.statement_month,
    s.outstanding_amount,
    s.utilization_percentage,
    s.payment_status,
    CASE
        WHEN s.payment_status = 'Overdue'
             AND s.utilization_percentage >= 90
            THEN 'Critical Risk'
        WHEN s.payment_status = 'Overdue'
             OR s.utilization_percentage >= 90
            THEN 'High Risk'
        WHEN s.utilization_percentage >= 70
            THEN 'Medium Risk'
        WHEN s.utilization_percentage >= 30
            THEN 'Low Risk'
        ELSE 'Very Low Risk'
    END AS risk_category
FROM monthly_statement s;

SELECT
    risk_category,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(outstanding_amount), 2) AS outstanding,
    ROUND(AVG(utilization_percentage), 2) AS avg_utilization
FROM customer_risk
GROUP BY risk_category
ORDER BY outstanding DESC;


/* 13 | CUSTOMER SEGMENTATION
   Segment customers using value, engagement, utilization and risk indicators. */

/* This recreates the customer metrics layer used for segmentation. */
DROP TABLE IF EXISTS customer_metrics;

/* This creates the consolidated customer metrics dataset. */
CREATE TABLE customer_metrics AS
WITH spend AS (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_spend,
        COUNT(*) AS transaction_count
    FROM transactions
    WHERE transaction_status = 'Approved'
    GROUP BY customer_id
),
util AS (
    SELECT
        customer_id,
        AVG(utilization_percentage) AS avg_utilization,
        MAX(utilization_percentage) AS max_utilization
    FROM monthly_statement
    GROUP BY customer_id
),
risk AS (
    SELECT
        customer_id,
        MAX(
            CASE
                WHEN risk_category IN ('Critical Risk','High Risk') THEN 1
                ELSE 0
            END
        ) AS high_risk_flag
    FROM customer_risk
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.income_segment,
    COALESCE(s.total_spend, 0) AS total_spend,
    COALESCE(s.transaction_count, 0) AS transaction_count,
    COALESCE(u.avg_utilization, 0) AS avg_utilization,
    COALESCE(u.max_utilization, 0) AS max_utilization,
    COALESCE(r.high_risk_flag, 0) AS high_risk_flag
FROM customers c
LEFT JOIN spend s ON s.customer_id = c.customer_id
LEFT JOIN util u ON u.customer_id = c.customer_id
LEFT JOIN risk r ON r.customer_id = c.customer_id;

/* This adds the final business segment assigned to each customer. */
ALTER TABLE customer_metrics
ADD COLUMN customer_segment VARCHAR(40);

UPDATE customer_metrics
SET customer_segment = CASE
    WHEN total_spend >= 200000
         AND avg_utilization < 50
         AND high_risk_flag = 0
        THEN 'Premium Customer'
    WHEN total_spend >= 200000
         AND avg_utilization >= 80
        THEN 'High Value - High Risk'
    WHEN total_spend < 50000
         AND transaction_count < 10
        THEN 'Low Engagement'
    WHEN income_segment IN ('High Income','Premium')
         AND total_spend < 100000
        THEN 'Growth Opportunity'
    WHEN high_risk_flag = 1
        THEN 'High Risk'
    ELSE 'Regular Customer'
END;

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(total_spend), 2) AS spend,
    ROUND(AVG(avg_utilization), 2) AS avg_utilization
FROM customer_metrics
GROUP BY customer_segment
ORDER BY spend DESC;


/* 14 | MONTH-OVER-MONTH TREND
   Measure monthly spend momentum using a window function. */

WITH monthly_spend AS (
    SELECT
        transaction_month,
        SUM(transaction_amount) AS spend
    FROM transactions
    WHERE transaction_status = 'Approved'
    GROUP BY transaction_month
),
trend AS (
    SELECT
        transaction_month,
        spend,
        LAG(spend) OVER (ORDER BY transaction_month) AS previous_spend
    FROM monthly_spend
)
SELECT
    transaction_month,
    ROUND(spend, 2) AS spend,
    ROUND(previous_spend, 2) AS previous_spend,
    ROUND(
        (spend - previous_spend) / NULLIF(previous_spend, 0) * 100,
        2
    ) AS mom_growth_pct
FROM trend
ORDER BY transaction_month;


/* 15 | PRODUCT & CUSTOMER RANKING
   Compare customers within card products and identify product-level leaders. */

WITH customer_card_spend AS (
    SELECT
        t.customer_id,
        cc.card_type,
        SUM(t.transaction_amount) AS spend
    FROM transactions t
    JOIN credit_cards cc ON cc.card_id = t.card_id
    WHERE t.transaction_status = 'Approved'
    GROUP BY t.customer_id, cc.card_type
)
SELECT
    customer_id,
    card_type,
    ROUND(spend, 2) AS spend,
    DENSE_RANK() OVER (
        PARTITION BY card_type
        ORDER BY spend DESC
    ) AS product_rank
FROM customer_card_spend
ORDER BY card_type, product_rank
LIMIT 100;


/* 16 | ANOMALY SCREEN
   Flag unusually large approved transactions for investigation. */

SELECT
    transaction_id,
    customer_id,
    card_id,
    transaction_date,
    merchant_category,
    transaction_amount
FROM transactions
WHERE transaction_status = 'Approved'
  AND transaction_amount >
      (
          SELECT AVG(transaction_amount)
                 + 3 * STDDEV(transaction_amount)
          FROM transactions
          WHERE transaction_status = 'Approved'
      )
ORDER BY transaction_amount DESC;


/* 17 | CUSTOMER 360
   Consolidate customer, card, spend, payment and credit-risk measures into
   the reporting layer. */

/* This replaces the reporting view with the latest Customer 360 logic. */
DROP VIEW IF EXISTS customer_360;

/* This creates the consolidated Customer 360 reporting view. */
CREATE VIEW customer_360 AS
WITH cards AS (
    SELECT
        customer_id,
        COUNT(*) AS total_cards,
        SUM(status = 'Active') AS active_cards,
        SUM(credit_limit) AS total_credit_limit,
        SUM(annual_fee) AS annual_fee_value
    FROM credit_cards
    GROUP BY customer_id
),
spend AS (
    SELECT
        customer_id,
        COUNT(*) AS total_transactions,
        COUNT(DISTINCT transaction_month) AS active_months,
        SUM(transaction_amount) AS total_spend,
        AVG(transaction_amount) AS avg_transaction
    FROM transactions
    WHERE transaction_status = 'Approved'
    GROUP BY customer_id
),
statements AS (
    SELECT
        customer_id,
        SUM(outstanding_amount) AS total_outstanding,
        AVG(utilization_percentage) AS avg_utilization,
        MAX(utilization_percentage) AS max_utilization,
        SUM(payment_status = 'Overdue') AS overdue_statements
    FROM monthly_statement
    GROUP BY customer_id
),
payments AS (
    SELECT
        customer_id,
        COUNT(*) AS total_payments,
        SUM(payment_status = 'Successful') AS successful_payments,
        SUM(
            CASE WHEN payment_status = 'Successful'
                 THEN payment_amount ELSE 0 END
        ) AS payment_value
    FROM payments
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.gender,
    c.age,
    c.age_group,
    c.city,
    c.state,
    c.income,
    c.income_segment,
    c.employment_type,
    c.marital_status,
    COALESCE(cards.total_cards, 0) AS total_cards,
    COALESCE(cards.active_cards, 0) AS active_cards,
    COALESCE(cards.total_credit_limit, 0) AS total_credit_limit,
    COALESCE(cards.annual_fee_value, 0) AS annual_fee_value,
    COALESCE(spend.total_transactions, 0) AS total_transactions,
    COALESCE(spend.active_months, 0) AS active_months,
    COALESCE(spend.total_spend, 0) AS total_spend,
    COALESCE(spend.avg_transaction, 0) AS avg_transaction,
    COALESCE(statements.total_outstanding, 0) AS total_outstanding,
    COALESCE(statements.avg_utilization, 0) AS avg_utilization,
    COALESCE(statements.max_utilization, 0) AS max_utilization,
    COALESCE(statements.overdue_statements, 0) AS overdue_statements,
    COALESCE(payments.total_payments, 0) AS total_payments,
    COALESCE(payments.successful_payments, 0) AS successful_payments,
    COALESCE(payments.payment_value, 0) AS payment_value,
    cm.customer_segment
FROM customers c
LEFT JOIN cards ON cards.customer_id = c.customer_id
LEFT JOIN spend ON spend.customer_id = c.customer_id
LEFT JOIN statements ON statements.customer_id = c.customer_id
LEFT JOIN payments ON payments.customer_id = c.customer_id
LEFT JOIN customer_metrics cm ON cm.customer_id = c.customer_id;


/* 18 | EXECUTIVE KPI OUTPUT
   Final reporting dataset for management review and Power BI consumption. */

SELECT
    COUNT(*) AS customers,
    SUM(active_cards) AS active_cards,
    ROUND(SUM(total_credit_limit), 2) AS credit_limit,
    ROUND(SUM(total_spend), 2) AS spend,
    ROUND(AVG(avg_transaction), 2) AS avg_transaction,
    ROUND(AVG(avg_utilization), 2) AS avg_utilization,
    ROUND(SUM(total_outstanding), 2) AS outstanding,
    SUM(overdue_statements) AS overdue_statements
FROM customer_360;

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(total_spend), 2) AS spend,
    ROUND(SUM(total_outstanding), 2) AS outstanding,
    ROUND(AVG(avg_utilization), 2) AS avg_utilization
FROM customer_360
GROUP BY customer_segment
ORDER BY spend DESC;


/* 19 | BUSINESS-FOCUSED OUTPUTS
   Produce actionable populations rather than only descriptive statistics. */

SELECT
    customer_id,
    customer_name,
    income_segment,
    total_spend,
    avg_utilization,
    total_outstanding,
    overdue_statements
FROM customer_360
WHERE customer_segment = 'High Value - High Risk'
ORDER BY total_outstanding DESC;

SELECT
    customer_id,
    customer_name,
    income_segment,
    total_spend,
    total_transactions,
    avg_utilization
FROM customer_360
WHERE customer_segment = 'Growth Opportunity'
ORDER BY income_segment DESC, total_spend DESC;

SELECT
    customer_id,
    customer_name,
    total_credit_limit,
    total_outstanding,
    max_utilization,
    overdue_statements
FROM customer_360
WHERE max_utilization >= 80
ORDER BY max_utilization DESC, total_outstanding DESC;


/*
20 | FINAL PROJECT SUMMARY
   Outcome:
   - Built a raw-to-analytics SQL workflow across customer, card, transaction,
     payment and statement data.
   - Standardized source attributes and converted reporting fields into usable
     numeric/date dimensions.
   - Created spend, utilization, payment, delinquency, risk and segmentation
     measures.
   - Used joins, CTEs, conditional logic and window functions for customer and
     portfolio analysis.
   - Produced a Customer 360 view suitable for Power BI/reporting.

   Dataset-level observations from the project data:
   - 12,000 customers, 18,000 cards, 120,000 transactions,
     60,000 payments and 36,000 monthly statements were analyzed.
   - Approved transactions represent 86,601 records with
     approximately 2,770,073,851 in approved spend and an average approved
     transaction of 31,987.
   - Classic is the largest card-product group by card count.
   - Average statement-level credit utilization is approximately 25.1%.
   - Approximately 17.5% of statement records are at or above
     70% utilization, providing a meaningful population for credit-risk review.
   - Approximately 6.0% of statement records are marked overdue.

   Key analytical challenges:
   - Source values required normalization before aggregation.
   - Financial exposure needed to be interpreted together with utilization and
     payment status rather than as isolated measures.
   - Customer-level metrics required careful aggregation to avoid duplication
     across cards, transactions and monthly statements.
   - Risk and segmentation thresholds are analytical assumptions and should be
     calibrated against actual portfolio policy before production use.

   Recommended next step:
   Connect customer_360 and the supporting monthly/category/risk outputs to
   Power BI for executive, customer-value and credit-risk reporting.
*/


/* END */
