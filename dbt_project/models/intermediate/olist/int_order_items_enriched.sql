{{ config(materialized='view', tags=['intermediate', 'ecommerce']) }}

with order_items as (

    select *
    from {{ ref('stg_order_items') }}

),

orders as (

    select *
    from {{ ref('stg_orders') }}

)

select
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.customer_id,

    oi.shipping_limit_ts,
    oi.price,
    oi.freight_value,

    oi.price + oi.freight_value as item_total_value,
    1 as quantity

from order_items oi
left join orders o
    on oi.order_id = o.order_id