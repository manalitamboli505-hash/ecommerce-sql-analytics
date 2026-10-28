# E-commerce SQL Analytics

A portfolio SQL project using synthetic e-commerce data to analyze sales, customers, products, profitability estimates, order outcomes, and regional performance.

> **Data disclosure:** The data is synthetic and does not represent a real company or real customers. Results are for learning and portfolio demonstration only.

## Dataset
- 240 synthetic customers
- 32 products across several categories
- 950 orders from 2025
- Multiple line items per order

## Skills demonstrated
Relational schema design, primary/foreign keys, constraints, indexes, joins, CTEs, conditional aggregation, date functions, `LAG`, `ROW_NUMBER`, `DENSE_RANK`, window aggregates, customer analysis, AOV, repeat purchase rate, and revenue trend analysis.

## Business questions
1. What are delivered orders, purchasing customers, and delivered net sales?
2. How does monthly sales change month over month?
3. Which products generate the most sales?
4. Which categories have the highest estimated profit and margin?
5. Which customers contribute the most sales?
6. What is the repeat-purchase rate?
7. Which customers may be inactive?
8. How is sales distributed across regions?
9. How do cancellation and return rates vary by month?
10. Which products lead within each category?
11. What is average order value, calculated per order?
12. Which payment methods are most common?

## Structure
```text
ecommerce_sql_analytics_project/
├── data/                         # Four linked CSV datasets
├── sql/
│   ├── 01_schema.sql             # Tables, constraints and indexes
│   ├── 02_business_analysis_queries.sql
│   └── load_data.py              # Builds a SQLite database
├── outputs/                      # Example query outputs
├── docs/business_questions.md
├── ecommerce_analytics.db
└── README.md
```

## Metric definitions and caveats
- Net sales = quantity × charged unit price × (1 − discount).
- Revenue queries count only `Delivered` orders.
- Estimated profit subtracts synthetic product costs; it excludes tax, shipping, overhead, and full return accounting.
- Average order value is calculated after summing line items per order.
- The inactivity query uses the maximum order date in this dataset as its reference date, not today's date.

