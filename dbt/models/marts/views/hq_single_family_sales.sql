{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

SELECT * 
EXCEPT (
    is_arms_length, 
    is_deed, 
    is_assessor_good, 
    is_over_price_floor,
    has_building,
    is_finished,
    is_single_family,
    is_duplicate_document,
    is_market_sale,

    instrument,
    quality1,
    quality2,
    analysis_quality,
    occupancy
)
FROM {{ ref('filtered_single_parcel_sales') }}
WHERE is_arms_length
AND is_deed
AND is_assessor_good
AND is_over_price_floor
AND has_building
AND is_finished
AND is_single_family
AND NOT is_duplicate_document
AND is_market_sale
ORDER BY sale_date DESC
