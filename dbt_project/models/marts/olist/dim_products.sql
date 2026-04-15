{{ config(materialized='table') }}

with products as (

    select *
    from {{ ref('stg_products') }}

)

select
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,

    product_length_cm * product_height_cm * product_width_cm as product_volume_cm3,

    case
        when product_length_cm is not null
         and product_height_cm is not null
         and product_width_cm is not null
        then true
        else false
    end as has_complete_dimensions,

    case
        when product_name_length is not null
         and product_description_length is not null
        then true
        else false
    end as has_complete_description

from products