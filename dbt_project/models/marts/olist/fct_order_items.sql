{{ config(materialized='table', tags=['mart', 'fact', 'ecommerce']) }}

with orders as (

    select *
    from {{ ref('stg_orders') }}

),

items_agg as (

    select *
    from {{ ref('int_orders_items_agg') }}

),

payments_agg as (

    select *
    from {{ ref('int_orders_payments_agg') }}

),

reviews_agg as (

    select *
    from {{ ref('int_orders_reviews_agg') }}

)

select
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_ts,
    o.order_approved_ts,
    o.order_delivered_carrier_ts,
    o.order_delivered_customer_ts,
    o.order_estimated_delivery_ts,

    coalesce(i.order_item_count, 0) as order_item_count,
    coalesce(i.distinct_products_count, 0) as distinct_products_count,
    coalesce(i.distinct_sellers_count, 0) as distinct_sellers_count,
    coalesce(i.order_items_value, 0) as order_items_value,
    coalesce(i.order_freight_value, 0) as order_freight_value,
    coalesce(i.order_total_value, 0) as order_total_value,

    coalesce(p.payment_count, 0) as payment_count,
    coalesce(p.total_payment_value, 0) as total_payment_value,
    p.max_payment_installments,

    r.review_score,

    timestamp_diff(o.order_approved_ts, o.order_purchase_ts, day) as days_to_approve,
    timestamp_diff(o.order_delivered_customer_ts, o.order_purchase_ts, day) as days_to_deliver,
    date_diff(date(o.order_delivered_customer_ts), date(o.order_estimated_delivery_ts), day) as delivery_delay_days,

    case
        when o.order_delivered_customer_ts is not null then true
        else false
    end as order_is_delivered,

    case
        when o.order_delivered_customer_ts is null then null
        when date_diff(date(o.order_delivered_customer_ts), date(o.order_estimated_delivery_ts), day) > 0 then true
        else false
    end as order_is_late_delivery

from orders o
left join items_agg i
    on o.order_id = i.order_id
left join payments_agg p
    on o.order_id = p.order_id
left join reviews_agg r
    on o.order_id = r.order_id