{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- Sale conditions that can appear in quality2, so id is unique.
SELECT
    id,
    quality,
    description
FROM {{ ref('valid_sale_conditions') }}
WHERE quality2
