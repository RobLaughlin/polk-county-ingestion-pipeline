{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

-- One row per recorded sale document, with what the sale covers as a whole: every parcel it lists.
-- The residence on dp is in fct_sales_single, on the same book and pg.
SELECT
    -- Keys
    sale_id,
    book,
    pg,
    dp_group_id,
    gp_group_id,
    dp_count,

    -- Sale
    sale_date,
    initial_entry_date,
    price AS price_dollars,
    seller,
    buyer,

    instrument,
    {# instrument_id, #}
    dim_quality1_conditions.quality AS quality1,
    {# quality1_id, #}
    dim_quality2_conditions.quality AS quality2,
    {# quality2_id, #}
    analysis_quality,
    {# analysis_quality_id, #}

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
INNER JOIN {{ ref('dim_instruments') }} AS dim_instruments
ON instrument_id = dim_instruments.id
INNER JOIN {{ ref('dim_quality1_conditions') }} AS dim_quality1_conditions
ON quality1_id = dim_quality1_conditions.id
INNER JOIN {{ ref('dim_quality2_conditions') }} AS dim_quality2_conditions
ON quality2_id = dim_quality2_conditions.id
INNER JOIN {{ ref('dim_analysis_qualities') }} AS dim_analysis_qualities
ON analysis_quality_id = dim_analysis_qualities.id