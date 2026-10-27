{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

SELECT
    -- Keys
    dim_buildings.building_id,
    dim_buildings.dp,

    {# occupancy_id, #}
    dim_occupancies.occupancy,

    {# residence_type_id, #}
    dim_residence_types.residence_type,

    {# bldg_style_id, #}
    dim_bldg_styles.bldg_style,

    {# exterior_wall_type_id, #}
    dim_exterior_wall_types.exterior_wall_type,

    {# roof_type_id, #}
    dim_roof_types.roof_type,

    {# roof_material_id, #}
    dim_roof_materials.roof_material,

    {# foundation_id, #}
    dim_foundations.foundation,

    {# heating_id, #}
    dim_heating_types.heating,

    {# fin_bsmt_qual1_id, #}
    dim_basement_qualities1.basement_quality AS fin_bsmt_qual1,

    {# fin_bsmt_qual2_id, #}
    dim_basement_qualities2.basement_quality AS fin_bsmt_qual2,

    -- Grade and condition
    {# grade_id, #}
    dim_grades.grade,
    dim_buildings.grade_adjustment,
    {# condition_id, #}
    dim_conditions.condition,

    -- Units and percentages
    dim_buildings.families,
    dim_buildings.brick_pct,
    dim_buildings.air_conditioning_pct,
    dim_buildings.completed_pct,
    dim_buildings.garage_brick_pct,

    -- Years
    dim_buildings.year_built,
    dim_buildings.eff_year_built,
    dim_buildings.year_remodel,
    dim_buildings.condo_year_built,

    -- When this version was seen
    dim_buildings.first_sale_date,
    dim_buildings.last_sale_date
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
