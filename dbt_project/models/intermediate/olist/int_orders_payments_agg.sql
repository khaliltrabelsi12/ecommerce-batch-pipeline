{{ config(materialized='view', tags=['intermediate', 'ecommerce']) }}

with payments as (

    select *
    from {{ ref('stg_order_payments') }}

)

select
    order_id,
    count(*) as payment_count,
    sum(payment_value) as total_payment_value,
    max(payment_installments) as max_payment_installments
from payments
group by order_id