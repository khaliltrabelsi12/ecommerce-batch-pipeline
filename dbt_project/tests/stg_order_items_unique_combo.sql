-- tests/stg_order_items_unique_combo.sql
select
    order_id,
    order_item_id,
    count(*) as n
from {{ ref('stg_order_items') }}
group by 1, 2
having count(*) > 1