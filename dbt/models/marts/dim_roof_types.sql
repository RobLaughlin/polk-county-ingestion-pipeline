{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

SELECT * FROM {{ ref('valid_roof_types') }}
