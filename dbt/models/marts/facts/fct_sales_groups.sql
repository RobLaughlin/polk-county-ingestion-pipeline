{{
    config(
        materialized='table',
        tags=['marts', 'facts']
    )
}}

-- One row per recorded sale document, with what the sale covers as a whole: every parcel it lists.
-- The residence on dp is in fct_sales_single, on the same book and pg.
SELECT
    -- Keys
    book,
    pg,
    dp_group_id,
    gp_group_id,

    -- Sale
    sale_date,
    initial_entry_date,
    price AS price_dollars,
    seller,
    buyer,
    instrument_id,
    quality1_id,
    quality2_id,
    analysis_quality_id,

    -- Assessed values
    land_full AS land_full_assessment_dollars,
    bldg_full AS bldg_full_assessment_dollars,
    total_full AS total_full_assessment_dollars,

    -- Land
    land_sf,
    land_acres,

    -- Detached structures
    detached_structs
FROM {{ ref('int_sales') }}
