{{ config(materialized='table') }}

with sellers as (

    select *
    from {{ ref('stg_sellers') }}

)

select
    seller_id,
    seller_zip_code_prefix as zip_code_prefix,
    seller_city as city,
    seller_state as state
from sellers