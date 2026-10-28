{{
    config(
        materialized='table',
        tags=['marts', 'reports']
    )
}}

SELECT
    -- Keys
    fct_sales_groups.sale_id,
    bridge_sales.book,
    bridge_sales.pg,
    fct_sales_groups.dp_group_id,
    fct_sales_groups.gp_group_id,
    fct_sales_groups.dp_count,

    -- Sale
    fct_sales_groups.sale_date,
    fct_sales_groups.initial_entry_date,
    fct_sales_groups.price_dollars,
    dim_sales_groups.seller,
    dim_sales_groups.buyer,

    dim_instruments.instrument,
    {# instrument_id, #}
    dim_quality1_conditions.quality AS quality1,
    {# quality1_id, #}
    dim_quality2_conditions.quality AS quality2,
    {# quality2_id, #}
    dim_analysis_qualities.analysis_quality,
    {# analysis_quality_id, #}

    -- Assessed values
    fct_sales_groups.land_full_assessment_dollars,
    fct_sales_groups.bldg_full_assessment_dollars,
    fct_sales_groups.total_full_assessment_dollars,

    -- Land
    fct_sales_groups.land_sf,
    fct_sales_groups.land_acres,

    -- Detached structures
    dim_sales_groups.detached_structs
FROM {{ ref('fct_sales_groups') }} AS fct_sales_groups
INNER JOIN {{ ref('bridge_sales') }} AS bridge_sales
ON fct_sales_groups.sale_id = bridge_sales.sale_id
INNER JOIN {{ ref('dim_sales_groups') }} AS dim_sales_groups
ON fct_sales_groups.sale_id = dim_sales_groups.sale_id
LEFT JOIN {{ ref('dim_instruments') }} AS dim_instruments
ON dim_sales_groups.instrument_id = dim_instruments.id
LEFT JOIN {{ ref('dim_quality1_conditions') }} AS dim_quality1_conditions
ON dim_sales_groups.quality1_id = dim_quality1_conditions.id
LEFT JOIN {{ ref('dim_quality2_conditions') }} AS dim_quality2_conditions
ON dim_sales_groups.quality2_id = dim_quality2_conditions.id
LEFT JOIN {{ ref('dim_analysis_qualities') }} AS dim_analysis_qualities
ON dim_sales_groups.analysis_quality_id = dim_analysis_qualities.id
