{{ config(materialized='table', tags=['mart', 'fact', 'ecommerce']) }}

with items as (

    select *
    from {{ ref('int_order_items_enriched') }}

),

order_stats as (

    select
        order_id,
        count(*) as order_item_count,
        sum(item_total_value) as order_total_value
    from {{ ref('int_order_items_enriched') }}
    group by order_id

)

select
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.customer_id,
    i.shipping_limit_ts,
    i.price,
    i.freight_value,
    i.item_total_value,
    i.quantity,
    os.order_item_count,
    safe_divide(i.item_total_value, os.order_total_value) as item_share_of_order_value
from items i
left join order_stats os
    on i.order_id = os.order_id