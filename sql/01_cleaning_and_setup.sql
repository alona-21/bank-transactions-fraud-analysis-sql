-- ============================================================
-- 01_cleaning_and_setup.sql
-- Financial Transactions Analysis (PostgreSQL, DBeaver)
-- Run order: 01 (once), then 02, 03, 04.
-- Re-running the ALTER statements will fail, because the columns
-- already have their new types.
-- ============================================================

-- 0. Database and import
-- CREATE DATABASE finance_db;
-- Tables were imported from CSV with the DBeaver Data Transfer wizard:
--   cards, fraud_labels, mcc_codes, transactions, users
-- The importer read money and date columns as text, so they are
-- converted below.

-- 1. Users: strip "$" and "," from money columns
ALTER TABLE users
  ALTER COLUMN per_capita_income TYPE numeric USING REGEXP_REPLACE(per_capita_income, '[$,]', '', 'g')::numeric,
  ALTER COLUMN yearly_income     TYPE numeric USING REGEXP_REPLACE(yearly_income,     '[$,]', '', 'g')::numeric,
  ALTER COLUMN total_debt        TYPE numeric USING REGEXP_REPLACE(total_debt,        '[$,]', '', 'g')::numeric;

-- 2. Cards: money to numeric, "MM/YYYY" text to date
ALTER TABLE cards
  ALTER COLUMN credit_limit   TYPE numeric USING REGEXP_REPLACE(credit_limit, '[$,]', '', 'g')::numeric,
  ALTER COLUMN expires        TYPE date    USING TO_DATE(expires, 'MM/YYYY'),
  ALTER COLUMN acct_open_date TYPE date    USING TO_DATE(acct_open_date, 'MM/YYYY');

-- 3. Transactions: date to timestamp, zip to text (restores leading
--    zeros lost on import), amount to numeric
ALTER TABLE transactions
  ALTER COLUMN "date" TYPE timestamp USING "date"::timestamp,
  ALTER COLUMN zip    TYPE text      USING LPAD(zip::bigint::text, 5, '0'),
  ALTER COLUMN amount TYPE numeric(12,2)
      USING NULLIF(REGEXP_REPLACE(amount, '[$,]', '', 'g'), '')::numeric;

-- 4. Primary keys
ALTER TABLE users        ADD PRIMARY KEY (id);
ALTER TABLE cards        ADD PRIMARY KEY (id);
ALTER TABLE mcc_codes    ADD PRIMARY KEY (mcc);
ALTER TABLE transactions ADD PRIMARY KEY (id);
ALTER TABLE fraud_labels ADD PRIMARY KEY (id);

-- 5. Indexes on the columns used for joins and filters
CREATE INDEX idx_txn_client ON transactions (client_id);
CREATE INDEX idx_txn_card   ON transactions (card_id);
CREATE INDEX idx_txn_date   ON transactions (date);
CREATE INDEX idx_txn_mcc    ON transactions (mcc);

-- 6. Refresh planner statistics
ANALYZE;

