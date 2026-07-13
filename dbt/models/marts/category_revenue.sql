-- Gold: revenue and order counts by category and country. Materialized as
-- Snappy Parquet so BI tools scan a tiny columnar table instead of the raw seed.
select
    product_category,
    country,
    count(*)                    as order_count,
    sum(quantity)               as units_sold,
    round(sum(line_total), 2)   as revenue
from {{ ref('stg_orders') }}
group by product_category, country
