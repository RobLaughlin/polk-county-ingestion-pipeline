{{
    config(
        materialized='table',
        tags=['marts', 'reports']
    )
}}

-- Every sale from single_parcel_sales, with a TRUE/FALSE column for each filter.
WITH flagged AS (
    SELECT
        *,
        -- Filters
        building_id IS NOT NULL AS has_building,
        COALESCE(quality1 = 'Arms Length' AND quality2 = 'No Code', FALSE) AS is_arms_length,
        COALESCE(instrument = 'Deed', FALSE) AS is_deed,
        COALESCE(analysis_quality = 'Good', FALSE) AS is_assessor_good,
        COALESCE(price_dollars > {{ sale_price_floor() }}, FALSE) AS is_over_price_floor,
        COALESCE(completed_pct IS NULL AND residence_type NOT IN ('Foundation', 'Partial Construction'), FALSE)
            AS is_finished,
        COALESCE(occupancy = 'Single Family', FALSE) AS is_single_family,
        -- Another document on the same dp and sale_date, e.g. a deed and its correction
        COUNT(DISTINCT sale_id) OVER (PARTITION BY dp, sale_date) > 1 AS is_duplicate_document
    FROM {{ ref('single_parcel_sales') }}
)

SELECT
    *,
    -- Passes every core filter; is_assessor_good and is_single_family stay separate choices
    is_arms_length
    AND is_deed
    AND is_over_price_floor
    AND has_building
    AND is_finished
    AND NOT is_duplicate_document AS is_market_sale
FROM flagged
