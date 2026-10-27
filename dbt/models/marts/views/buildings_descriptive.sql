{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

SELECT
    -- Keys
    building_id,
    dp,

    {# occupancy_id, #}
    occupancy,

    {# residence_type_id, #}
    residence_type,

    {# bldg_style_id, #}
    bldg_style,

    {# exterior_wall_type_id, #}
    exterior_wall_type,

    {# roof_type_id, #}
    roof_type,

    {# roof_material_id, #}
    roof_material,

    {# foundation_id, #}
    foundation,

    {# heating_id, #}
    heating,

    {# fin_bsmt_qual1_id, #}
    dim_basement_qualities1.basement_quality AS fin_bsmt_qual1,

    {# fin_bsmt_qual2_id, #}
    dim_basement_qualities2.basement_quality AS fin_bsmt_qual2,

    -- Grade and condition
    {# grade_id, #}
    grade,
    grade_adjustment,
    {# condition_id, #}
    condition,

    -- Units and percentages
    families,
    brick_pct,
    air_conditioning_pct,
    completed_pct,
    garage_brick_pct,

    -- Years
    year_built,
    eff_year_built,
    year_remodel,
    condo_year_built,

    -- When this version was seen
    first_sale_date,
    last_sale_date
FROM {{ ref('dim_buildings') }} AS dim_buildings
LEFT JOIN {{ ref('dim_occupancies') }} AS dim_occupancies
ON dim_buildings.occupancy_id = dim_occupancies.id
LEFT JOIN {{ ref('dim_residence_types') }} AS dim_residence_types
ON dim_buildings.residence_type_id = dim_residence_types.id
LEFT JOIN {{ ref('dim_bldg_styles') }} AS dim_bldg_styles
ON dim_buildings.bldg_style_id = dim_bldg_styles.id
LEFT JOIN {{ ref('dim_exterior_wall_types') }} AS dim_exterior_wall_types
ON dim_buildings.exterior_wall_type_id = dim_exterior_wall_types.id
LEFT JOIN {{ ref('dim_roof_types') }} AS dim_roof_types
ON dim_buildings.roof_type_id = dim_roof_types.id
LEFT JOIN {{ ref('dim_roof_materials') }} AS dim_roof_materials
ON dim_buildings.roof_material_id = dim_roof_materials.id
LEFT JOIN {{ ref('dim_foundations') }} AS dim_foundations
ON dim_buildings.foundation_id = dim_foundations.id
LEFT JOIN {{ ref('dim_heating_types') }} AS dim_heating_types
ON dim_buildings.heating_id = dim_heating_types.id
-- Both basement qualities use the same lookup, so it's joined once for each
LEFT JOIN {{ ref('dim_basement_qualities') }} AS dim_basement_qualities1
ON dim_buildings.fin_bsmt_qual1_id = dim_basement_qualities1.id
LEFT JOIN {{ ref('dim_basement_qualities') }} AS dim_basement_qualities2
ON dim_buildings.fin_bsmt_qual2_id = dim_basement_qualities2.id
LEFT JOIN {{ ref('dim_grades') }} AS dim_grades
ON dim_buildings.grade_id = dim_grades.id
LEFT JOIN {{ ref('dim_conditions') }} AS dim_conditions
ON dim_buildings.condition_id = dim_conditions.id

