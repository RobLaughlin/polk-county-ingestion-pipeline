{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

SELECT
    *
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
-- is_market_sale covers the core filters: arm's length, deed, over the price floor, a finished
-- building, and not a duplicate document
WHERE
    is_market_sale
    AND is_assessor_good
    AND is_single_family
