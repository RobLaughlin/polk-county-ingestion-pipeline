{{
    config(
        materialized='table',
        tags=['marts', 'reports']
    )
}}

SELECT
    -- Keys
    fct_sales_groups.sale_id,
    dim_sales.book,
    dim_sales.pg,
    fct_sales_groups.dp_group_id,
    fct_sales_groups.gp_group_id,
    dim_dp_groups.dp_count,
    dim_gp_groups.gp_count,

    -- Sale
    fct_sales_groups.sale_date,
    fct_sales_groups.initial_entry_date,
    fct_sales_groups.price_dollars,
    dim_sales.seller,
    dim_sales.buyer,

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
    dim_sales.detached_structs
FROM {{ ref('fct_sales_groups') }} AS fct_sales_groups
INNER JOIN {{ ref('dim_sales') }} AS dim_sales
ON fct_sales_groups.sale_id = dim_sales.sale_id
INNER JOIN {{ ref('dim_dp_groups') }} AS dim_dp_groups
ON fct_sales_groups.dp_group_id = dim_dp_groups.group_id
-- A sale with a blank gps has no gp group, so its gp_count is NULL.
LEFT JOIN {{ ref('dim_gp_groups') }} AS dim_gp_groups
ON fct_sales_groups.gp_group_id = dim_gp_groups.group_id
LEFT JOIN {{ ref('dim_instruments') }} AS dim_instruments
ON dim_sales.instrument_id = dim_instruments.id
LEFT JOIN {{ ref('dim_quality1_conditions') }} AS dim_quality1_conditions
ON dim_sales.quality1_id = dim_quality1_conditions.id
LEFT JOIN {{ ref('dim_quality2_conditions') }} AS dim_quality2_conditions
ON dim_sales.quality2_id = dim_quality2_conditions.id
LEFT JOIN {{ ref('dim_analysis_qualities') }} AS dim_analysis_qualities
ON dim_sales.analysis_quality_id = dim_analysis_qualities.id
