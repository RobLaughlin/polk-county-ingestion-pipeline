{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- Sale conditions that can appear in quality1, so id is unique.
SELECT
    id,
    quality,
    description
FROM {{ ref('valid_sale_conditions') }}
WHERE quality1
