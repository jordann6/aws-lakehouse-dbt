-- Gold: daily revenue trend, one row per calendar day. The kind of table a
-- dashboard's time-series chart reads directly.
select
    order_date,
    count(*)                    as order_count,
    round(sum(line_total), 2)   as revenue,
    round(avg(line_total), 2)   as avg_order_value
from {{ ref('stg_orders') }}
group by order_date
