{{ config(materialized='view', tags=['intermediate', 'ecommerce']) }}

with order_items as (

    select *
    from {{ ref('stg_order_items') }}

)

select
    order_id,
    count(*) as order_item_count,
    count(distinct product_id) as distinct_products_count,
    count(distinct seller_id) as distinct_sellers_count,
    sum(price) as order_items_value,
    sum(freight_value) as order_freight_value,
    sum(price + freight_value) as order_total_value
from order_items
group by order_id