-- ============================================================
-- 03_spending_analysis.sql
-- Spending patterns. Amounts are net of refunds (negative amounts
-- are included).
-- ============================================================

-- 1. Monthly volume and spend
-- Finding: in the months reviewed (2016 to mid-2017) volume stays between
-- about 107K and 118K transactions and spend between about $4.6M and
-- $5.1M per month, with no strong growth. February is lower because it
-- has fewer days.   [CHECK: confirm the pattern holds for all 46 months]
SELECT DATE_TRUNC('month', date) AS month,
       COUNT(*)    AS txns,
       SUM(amount) AS total
FROM transactions
GROUP BY 1 ORDER BY 1;

-- 2. Top spending categories
-- Finding: Money Transfer leads spend ($21.1M, about $90 per transaction);
-- Grocery Stores lead volume (639K transactions, about $26 each);
-- Utilities have the highest average ticket of the top 10 (about $113).
SELECT m.description,
       COUNT(*)      AS txns,
       SUM(t.amount) AS total
FROM transactions t
JOIN mcc_codes m ON m.mcc = t.mcc
GROUP BY m.description
ORDER BY total DESC
LIMIT 10;
