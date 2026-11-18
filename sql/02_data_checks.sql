-- ============================================================
-- 02_data_checks.sql
-- Checks run after cleaning. Findings are in the comments.
-- ============================================================

-- 1. Row counts (each matched the CSV line count minus the header)
SELECT COUNT(*) FROM cards;          -- 6,146
SELECT COUNT(*) FROM users;          -- 2,000
SELECT COUNT(*) FROM mcc_codes;      -- 109
SELECT COUNT(*) FROM transactions;   -- 5,346,183
SELECT COUNT(*) FROM fraud_labels;   -- 3,581,984

-- 2. Column types after conversion
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- 3. Date range and amount range
-- Finding: 2016-01-01 to 2019-10-31 (the source data ends in October 2019);
-- amounts from -500 (refunds) to 6,613.44; no NULL amounts.
SELECT MIN(date), MAX(date), MIN(amount), MAX(amount) FROM transactions;
SELECT COUNT(*) FROM transactions WHERE amount IS NULL;

-- 4. Implausible incomes in users
-- Finding: several users have yearly_income under 1,000 (the lowest is 1)
-- and per_capita_income of 0. Income analysis should filter
-- yearly_income >= 1000.
SELECT COUNT(*) FROM users WHERE yearly_income < 1000;   -- [count not recorded]
SELECT id, yearly_income, per_capita_income, total_debt
FROM users ORDER BY yearly_income LIMIT 10;

-- 5. Empty strings in text columns (not run yet)
-- The errors column uses '' (not NULL) for "no error".
SELECT COUNT(*) FROM transactions WHERE errors = '';

-- 6. How many transactions have a fraud label?
-- Finding: No 3,576,375 | Yes 5,609 | no label 1,764,199 (about 33%).
-- The fraud file in the source dataset is a training split, so only
-- about two-thirds of transactions are labelled. Fraud analysis uses
-- labelled rows only (INNER JOIN). NULL is never treated as "not fraud".
SELECT f.is_fraud, COUNT(*) AS txns
FROM transactions t
LEFT JOIN fraud_labels f ON f.id = t.id
GROUP BY f.is_fraud;

-- 7. Are labels missing from one period?
-- Finding: about 67% labelled in every year (and in every hour of the
-- day), so the missing labels are spread evenly.
SELECT DATE_TRUNC('year', t.date) AS yr,
       COUNT(*)    AS txns,
       COUNT(f.id) AS labelled
FROM transactions t
LEFT JOIN fraud_labels f ON f.id = t.id
GROUP BY 1 ORDER BY 1;
