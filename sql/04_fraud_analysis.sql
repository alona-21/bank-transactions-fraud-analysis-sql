-- ============================================================
-- 04_fraud_analysis.sql
-- All fraud queries use labelled transactions only (INNER JOIN to
-- fraud_labels). Overall: 5,609 fraud of 3,581,984 labelled = 0.157%.
-- ============================================================

-- 1. By merchant category (min 10,000 labelled transactions)
-- Finding: highest rates are Family Clothing Stores (0.996%),
-- Department Stores (0.830%), Digital Goods (0.803%), Discount Stores
-- (0.572%). Department Stores hold 1,057 cases, about 19% of all fraud.
-- Money Transfer is the top category by spend but its fraud rate is
-- 0.139%, slightly below average.
SELECT m.description,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
JOIN mcc_codes m ON m.mcc = t.mcc
GROUP BY m.description
HAVING COUNT(*) >= 10000
ORDER BY fraud_pct DESC
LIMIT 15;

-- 2. By amount band
-- Finding: about 0.12% below $100, then 0.429% for $100-500 and
-- 1.346% for $500+. Transactions of $100 or more are about 12% of
-- labelled transactions but 1,882 of 5,609 fraud cases (about 34%).
SELECT CASE WHEN t.amount < 0   THEN '0 refund'
            WHEN t.amount < 20  THEN '1 under 20'
            WHEN t.amount < 100 THEN '2 20-100'
            WHEN t.amount < 500 THEN '3 100-500'
            ELSE                     '4 500+' END AS band,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
GROUP BY 1 ORDER BY 1;

-- 3. Average and total amount, fraud vs not fraud
-- Finding: the average fraud transaction is $102.69 against $42.65 for
-- legitimate ones (2.4x). Fraud is 0.16% of labelled transactions but
-- about 0.38% of labelled dollars ($575,978).
SELECT f.is_fraud,
       COUNT(*)               AS txns,
       ROUND(AVG(t.amount),2) AS avg_amount,
       SUM(t.amount)          AS total_amount
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
GROUP BY f.is_fraud;

-- 4. By payment channel
-- Finding: Online 0.502% (2,181 of 434,317), Chip 0.117%, Swipe 0.073%.
-- Online is 12% of labelled transactions but 39% of fraud cases.
SELECT t.use_chip,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
GROUP BY t.use_chip
ORDER BY fraud_pct DESC;

-- 5. Channel x amount: does the risk compound?
-- Finding: in-person under $100: 0.091%; in-person $100+: 0.251%;
-- online under $100: 0.318%; online $100+: 1.662% (991 of 59,629).
-- The combined rate is higher than the two effects multiplied (about
-- 0.88%). Online $100+ transactions are 1.7% of labelled transactions
-- but 17.7% of fraud cases.
SELECT (t.use_chip = 'Online Transaction') AS is_online,
       (t.amount >= 100)                   AS is_100_plus,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
GROUP BY 1, 2
ORDER BY 1, 2;

-- 6. By error type
-- Finding: baseline (no error) is 0.153%. Bad CVV 2.014% (34 of 1,688),
-- Bad Expiration 1.094%, Bad PIN 0.974% (84 of 8,625), Bad Card Number
-- 0.65%. Insufficient Balance (0.193%) and Technical Glitch (0.153%)
-- are about baseline. Only about 1.6% of labelled transactions carry an
-- error, and they hold about 4% of fraud cases (230 of 5,609).
-- (The errors column holds '' for no error, so NULLIF is needed.)
SELECT COALESCE(NULLIF(t.errors, ''), 'No error') AS error_type,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
GROUP BY 1
ORDER BY labelled_txns DESC;

-- 7. By time of day
-- Finding: fraud is concentrated in the daytime. 13:00-19:59 has the
-- highest rate (0.245%, 3,244 cases); 06:00-12:59 is 0.136% (2,278
-- cases). From 20:00 to 05:59 the rate is about 0.015% (87 cases in
-- 591,304 labelled transactions, 16.5% of volume). About 98% of fraud
-- falls between 06:00 and 19:59. The labelled share is about 67% in
-- every hour, so this is not a labelling gap, and volume stays at about
-- 170K transactions per hour from 20:00 to 22:00. Real-world fraud
-- rarely stops this abruptly, which is consistent with a simulated
-- dataset.
SELECT CASE WHEN EXTRACT(HOUR FROM t.date) < 6  THEN '1 00-05'
            WHEN EXTRACT(HOUR FROM t.date) < 13 THEN '2 06-12'
            WHEN EXTRACT(HOUR FROM t.date) < 20 THEN '3 13-19'
            ELSE                                     '4 20-23' END AS time_band,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
GROUP BY 1 ORDER BY 1;

-- 8. By customer age band
-- Finding: flat at 0.14%-0.15% for ages 25-64; 65+ is 0.191%. Under 25
-- has only 9,625 transactions (16 fraud cases), too few to read.
-- Caveat: current_age is the age at the dataset's reference date, not at
-- the time of each transaction.
SELECT CASE WHEN u.current_age < 25 THEN '1 under 25'
            WHEN u.current_age < 35 THEN '2 25-34'
            WHEN u.current_age < 50 THEN '3 35-49'
            WHEN u.current_age < 65 THEN '4 50-64'
            ELSE                         '5 65+' END AS age_band,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
JOIN users u ON u.id = t.client_id
GROUP BY 1 ORDER BY 1;

-- 9. By card type and whether the card has a chip
-- Finding: all six groups fall between 0.139% and 0.218%, with no
-- consistent chip effect (prepaid debit is highest at about 0.2%).
-- How the transaction was made (use_chip) matters far more than
-- whether the card has a chip (has_chip).
SELECT c.card_type, c.has_chip,
       COUNT(*) AS labelled_txns,
       COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') AS fraud_txns,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud = 'Yes') / COUNT(*), 3) AS fraud_pct
FROM transactions t
JOIN fraud_labels f ON f.id = t.id
JOIN cards c ON c.id = t.card_id
GROUP BY 1, 2
ORDER BY fraud_pct DESC;
