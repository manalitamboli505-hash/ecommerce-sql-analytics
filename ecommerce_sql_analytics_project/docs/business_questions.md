# Business Questions: Interview Notes

For each question, describe the SQL technique used, what the result means, one possible business action, and one limitation.

- Monthly sales: CTE, date grouping, `LAG`, growth calculation.
- Product and category performance: joins and aggregation.
- Customer value: customer-level grouping and ranking.
- Repeat purchase rate: conditional aggregation over customer order counts.
- Inactivity: `LEFT JOIN`, `MAX`, date arithmetic.
- Regional contribution: window aggregate and `DENSE_RANK`.
- Product ranking within category: `ROW_NUMBER` partitioned by category.
- Average order value: aggregate to one row per order before taking the average.
