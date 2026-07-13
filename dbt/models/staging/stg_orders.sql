-- Silver: type and clean the raw seed. Cast the string order_date to a real
-- date, drop rows with a non-positive quantity or price (data-quality floor),
-- and expose a computed line_total the marts can trust.
with source as (

    select * from {{ ref('raw_orders') }}

),

cleaned as (

    select
        order_id,
        customer_id,
        date(date_parse(order_date, '%Y-%m-%d')) as order_date,
        lower(product_category)                  as product_category,
        upper(country)                           as country,
        quantity,
        unit_price,
        round(quantity * unit_price, 2)          as line_total
    from source
    where quantity > 0
      and unit_price > 0

)

select * from cleaned
