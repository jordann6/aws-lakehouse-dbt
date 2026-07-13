-- Singular test: total revenue in the gold category mart must equal total
-- line_total in the silver staging model. If a transform silently dropped or
-- double-counted rows, the two sums diverge and this test returns rows (fail).
with gold as (
    select sum(revenue) as total from {{ ref('category_revenue') }}
),
silver as (
    select round(sum(line_total), 2) as total from {{ ref('stg_orders') }}
)
select gold.total as gold_total, silver.total as silver_total
from gold, silver
where abs(gold.total - silver.total) > 0.01
