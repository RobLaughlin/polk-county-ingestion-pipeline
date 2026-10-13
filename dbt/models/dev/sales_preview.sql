{{ config(materialized='table') }}

select *
from {{ source('raw', 'sales_raw') }}
limit 100;