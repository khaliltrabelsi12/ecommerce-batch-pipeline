{{ config(materialized='view', tags=['intermediate', 'ecommerce']) }}

with reviews as (

    select *
    from {{ ref('stg_order_reviews') }}

)

select
    order_id,
    avg(review_score) as review_score
from reviews
group by order_id