# Fraud and Spending Analysis of Bank Card Transactions

A SQL project in PostgreSQL on about 5.3 million card transactions (2016 to October 2019). It asks where fraud concentrates and which transaction, customer, and card attributes are worth screening on.

## Data

- **Source:** *Financial Transactions Dataset: Analytics*, created by Caixabank Tech for the 2024 AI Hackathon, on Kaggle. [add link to the dataset page]
- **License:** Apache 2.0.
- **What I used:** a subset of the original (about 1.4 GB, 2010s). [add one line on how the subset was made]

| Table | Rows | Notes |
|---|---|---|
| transactions | 5,346,183 | 2016-01-01 to 2019-10-31 |
| fraud_labels | 3,581,984 | labels for about 67% of transactions |
| users | 2,000 | customer demographics and income |
| cards | 6,146 | card type, limit, chip; card numbers and CVV not used |
| mcc_codes | 109 | merchant category descriptions |

The data files are not included in this repository. Download them from Kaggle and import them into PostgreSQL (the setup steps are in `sql/01_cleaning_and_setup.sql`).

## Tools

PostgreSQL and DBeaver.

## Process

1. Imported the CSV files and fixed the column types (money columns stored as text with `$`, dates stored as text, ZIP codes read as numbers).
2. Added primary keys and indexes so joins on 5.3 million rows run in seconds.
3. Checked row counts against the source files, the date and amount ranges, and the share of transactions with a fraud label.
4. Analyzed spending, then fraud by category, amount, payment channel, error type, time of day, customer age, and card type.

## Key findings

All fraud rates use labelled transactions only. Overall: 5,609 fraud cases in 3,581,984 labelled transactions (0.157%).

1. **Payment channel and amount drive fraud risk.** Online transactions have a 0.502% fraud rate against 0.117% for chip and 0.073% for swipe. Online transactions are 12% of labelled volume but 39% of fraud cases. Fraud is flat at about 0.12% under $100, then rises to 0.429% for $100 to $500 and 1.346% above $500.
2. **The two factors compound.** Online transactions of $100 or more have a fraud rate of 1.662%, about 10 times the overall rate. They are 1.7% of transactions but 17.7% of fraud cases. Reviewing only these would cover roughly a fifth of fraud, though about 98% of the flagged transactions are legitimate, so this suits prioritising reviews, not blocking.
3. **Some merchant categories stand out.** Family Clothing (0.996%), Department Stores (0.830%), and Digital Goods (0.803%) have rates 5 to 6 times the average. Department Stores alone hold about 19% of all fraud cases. Money Transfer is the largest category by spend ($21.1M) but has a below-average fraud rate (0.139%).
4. **Fraud transactions are larger.** The average fraud transaction is $102.69 against $42.65 for legitimate ones.
5. **Security errors carry a signal, but it's narrow.** Bad CVV (2.014%), Bad Expiration (1.094%), and Bad PIN (0.974%) transactions have a much higher fraud rate than the 0.153% baseline. However, only 1.6% of transactions have an error, and they hold about 4% of fraud cases.
6. **Customer and card attributes matter little.** Fraud rates are 0.14% to 0.15% for ages 25 to 64 and 0.191% for 65 and over. Across card types and chip status the range is 0.139% to 0.218%, with no consistent chip effect. In this dataset the fraud signal sits in the transaction (channel, amount, merchant category), not in who the customer is or what card they hold.
7. **Time of day.** Fraud is 0.21% to 0.32% per hour from 13:00 to 19:00 and falls to near zero from 20:00. [add hours 00:00-12:00 after running the time-band query]

## Spending patterns

- Monthly volume is steady at roughly 107K to 118K transactions and $4.6M to $5.1M per month. [confirm across all 46 months]
- Money Transfer leads spending ($21.1M). Grocery Stores lead volume (639K transactions at about $26 each). Utilities have the highest average ticket of the top ten (about $113).

## Limitations

- About 33% of transactions have no fraud label (the source labels file is a training split). The missing labels are spread evenly by year and hour, but fraud counts apply only to the labelled two-thirds.
- Only 5,609 fraud cases exist, so rates for small categories and error types are noisy. Category rankings use a minimum of 10,000 labelled transactions.
- The dataset is described as built for synthetic fraud detection, and some patterns (swipe being the safest channel, fraud almost vanishing after 8 PM) are unlike real-world fraud. Treat the findings as patterns in this dataset.
- 2019 covers January to October only.
- `current_age` is age at the dataset's reference date, not at transaction time. With only 2,000 customers, age groups are really groups of customers.
- A few users have a yearly income under $1,000 and a per-capita income of 0 and were excluded from income analysis.

## Repository structure

```
sql/
  01_cleaning_and_setup.sql    column types, keys, indexes
  02_data_checks.sql           counts, ranges, label coverage
  03_spending_analysis.sql     monthly spend, top categories
  04_fraud_analysis.sql        fraud analysis queries and findings
```

Run the files in order. Findings are written as comments above each query.
