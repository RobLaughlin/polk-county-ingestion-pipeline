-- depends_on: {{ ref('raw_sales_null_counts') }}

{{ 
    config(
        materialized='table',
        tags=['staging']
    )
}}

SELECT *
FROM {{ source('raw', 'sales_raw') }}

