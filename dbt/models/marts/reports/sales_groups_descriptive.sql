{{
    config(
        materialized='table',
        tags=['marts', 'reports']
    )
}}

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
    price_dollars,
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
    land_full_assessment_dollars,
    bldg_full_assessment_dollars,
    total_full_assessment_dollars,

    -- Land
    land_sf,
    land_acres,

    -- Detached structures
    detached_structs
FROM {{ ref('fct_sales_groups') }}
LEFT JOIN {{ ref('dim_instruments') }} AS dim_instruments
ON instrument_id = dim_instruments.id
LEFT JOIN {{ ref('dim_quality1_conditions') }} AS dim_quality1_conditions
ON quality1_id = dim_quality1_conditions.id
LEFT JOIN {{ ref('dim_quality2_conditions') }} AS dim_quality2_conditions
ON quality2_id = dim_quality2_conditions.id
LEFT JOIN {{ ref('dim_analysis_qualities') }} AS dim_analysis_qualities
ON analysis_quality_id = dim_analysis_qualities.id