{{ config(materialized='table') }}

with customers as (

    select *
    from {{ ref('stg_customers') }}

),

orders as (

    select *
    from {{ ref('stg_orders') }}

),

order_items as (

    select *
    from {{ ref('stg_order_items') }}

),

customer_orders as (

    select
        c.customer_unique_id,
        c.customer_id,
        c.customer_city,
        c.customer_state,
        c.customer_zip_code_prefix,
        o.order_id,
        o.order_purchase_ts,
        o.order_delivered_customer_ts,
        o.order_estimated_delivery_ts
    from customers c
    left join orders o
        on c.customer_id = o.customer_id

),

customer_order_values as (

    select
        co.customer_unique_id,
        co.customer_id,
        co.customer_city,
        co.customer_state,
        co.customer_zip_code_prefix,
        co.order_id,
        co.order_purchase_ts,
        co.order_delivered_customer_ts,
        co.order_estimated_delivery_ts,
        coalesce(sum(coalesce(oi.price, 0) + coalesce(oi.freight_value, 0)), 0) as order_value
    from customer_orders co
    left join order_items oi
        on co.order_id = oi.order_id
    group by
        co.customer_unique_id,
        co.customer_id,
        co.customer_city,
        co.customer_state,
        co.customer_zip_code_prefix,
        co.order_id,
        co.order_purchase_ts,
        co.order_delivered_customer_ts,
        co.order_estimated_delivery_ts

),

customer_agg as (

    select
        customer_unique_id,
        min(customer_id) as first_customer_id,
        min(customer_zip_code_prefix) as zip_code_prefix,
        min(customer_city) as city,
        min(customer_state) as state,
        count(distinct order_id) as total_orders,
        round(coalesce(sum(order_value), 0), 2) as lifetime_value,
        round(coalesce(avg(order_value), 0), 2) as avg_order_value,
        min(order_purchase_ts) as first_order_at,
        max(order_purchase_ts) as last_order_at,
        avg(
            date_diff(date(order_delivered_customer_ts), date(order_estimated_delivery_ts), day)
        ) as avg_delivery_delay_days
    from customer_order_values
    group by customer_unique_id

)

select
    customer_unique_id,
    first_customer_id as customer_id,
    zip_code_prefix,
    city,
    state,
    total_orders,
    lifetime_value,
    avg_order_value,
    first_order_at,
    last_order_at,
    avg_delivery_delay_days,
    case
        when total_orders = 1 then 'one_time'
        else 'repeat'
    end as customer_type
from customer_agg