{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

SELECT * FROM {{ ref('valid_grades') }}
