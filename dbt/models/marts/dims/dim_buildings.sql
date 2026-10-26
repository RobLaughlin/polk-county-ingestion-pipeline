{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per version of the building on a parcel. A new version starts whenever any
-- building column changes between sales (e.g. a remodel or a new condition rating).
SELECT
    -- Keys
    building_id,
    dp,

    -- Codes
    occupancy_id,
    residence_type_id,
    bldg_style_id,
    exterior_wall_type_id,
    roof_type_id,
    roof_material_id,
    foundation_id,
    heating_id,
    fin_bsmt_qual1_id,
    fin_bsmt_qual2_id,

    -- Grade and condition
    grade_id,
    grade_adjustment,
    condition_id,

    -- Units and percentages
    families,
    percent_brick AS brick_pct,
    air_conditioning AS air_conditioning_pct,
    percent_complete AS completed_pct,
    garage_brick AS garage_brick_pct,

    -- Years
    year_built,
    eff_year_built,
    year_remodel,
    condo_year_built,

    -- When this version was seen
    MIN(sale_date) AS first_sale_date,
    MAX(sale_date) AS last_sale_date
FROM {{ ref('int_sales') }}
WHERE building_id IS NOT NULL
-- Grouping by the same columns building_id hashes: if this list and the macro ever drift,
-- the build fails or the unique test on building_id does.
GROUP BY building_id, dp, {{ building_columns() | join(', ') }}
