{{
    config(
        materialized='table',
        tags=['intermediate', 'sales']
    )
}}

-- Coded columns become IDs from the dim_* lookups (see the lookup_id macro).
-- grade (e.g. '4-05') splits into grade_id and grade_adjustment. A grade that doesn't parse
-- makes both NULL, and a grade with no adjustment (e.g. '3') gets an adjustment of 0.
WITH coded AS (
    SELECT
        sales.* EXCEPT (
            instrument, quality1, quality2, analysis_quality,
            occupancy, residence_type, bldg_style, exterior_wall_type, roof_type, roof_material, foundation, heating,
            fin_bsmt_qual1, fin_bsmt_qual2,
            condition, grade
        )
        REPLACE (
            -- Set totals to NULL if they doesn't equal their parts
            IF(sales.total_living_area = sales.main_living_area + sales.upper_living_area + sales.fin_attic_area, sales.total_living_area, NULL) AS total_living_area,
            IF(sales.total_full = sales.land_full + sales.bldg_full, sales.total_full, NULL) AS total_full
        ),

        {{ lookup_id('sales.instrument', 'dim_instruments', 'instrument') }} AS instrument_id,
        {{ lookup_id('sales.quality1', 'dim_quality1_conditions', 'quality') }} AS quality1_id,
        {{ lookup_id('sales.quality2', 'dim_quality2_conditions', 'quality') }} AS quality2_id,
        {{ lookup_id('sales.analysis_quality', 'dim_analysis_qualities', 'analysis_quality') }} AS analysis_quality_id,

        {{ lookup_id('sales.occupancy', 'dim_occupancies', 'occupancy') }} AS occupancy_id,
        {{ lookup_id('sales.residence_type', 'dim_residence_types', 'residence_type') }} AS residence_type_id,
        {{ lookup_id('sales.bldg_style', 'dim_bldg_styles', 'bldg_style') }} AS bldg_style_id,
        {{ lookup_id('sales.exterior_wall_type', 'dim_exterior_wall_types', 'exterior_wall_type') }} AS exterior_wall_type_id,
        {{ lookup_id('sales.roof_type', 'dim_roof_types', 'roof_type') }} AS roof_type_id,
        {{ lookup_id('sales.roof_material', 'dim_roof_materials', 'roof_material') }} AS roof_material_id,
        {{ lookup_id('sales.foundation', 'dim_foundations', 'foundation') }} AS foundation_id,
        {{ lookup_id('sales.heating', 'dim_heating_types', 'heating') }} AS heating_id,
        {{ lookup_id('sales.fin_bsmt_qual1', 'dim_basement_qualities', 'basement_quality') }} AS fin_bsmt_qual1_id,
        {{ lookup_id('sales.fin_bsmt_qual2', 'dim_basement_qualities', 'basement_quality') }} AS fin_bsmt_qual2_id,

        {{ lookup_id('sales.condition', 'dim_conditions', 'condition') }} AS condition_id,

        -- The base grade digit, or 'Other' (7) for a digit with no row of its own.
        -- No ELSE: a NULL or unparseable grade gives NULL.
        CASE
            WHEN REGEXP_CONTAINS(sales.grade, r'^[0-9]([+-]?[0-9]+)?$') THEN COALESCE(
                (SELECT codes.id FROM {{ ref('dim_grades') }} AS codes WHERE codes.id = CAST(LEFT(sales.grade, 1) AS INT64)),
                (SELECT codes.id FROM {{ ref('dim_grades') }} AS codes WHERE codes.grade = 'Other')
            )
        END AS grade_id,

        CASE
            WHEN REGEXP_CONTAINS(sales.grade, r'^[0-9]([+-]?[0-9]+)?$')
                THEN COALESCE(CAST(REGEXP_EXTRACT(sales.grade, r'^[0-9]([+-]?[0-9]+)$') AS INT64), 0)
        END AS grade_adjustment
    FROM {{ ref('stg_sale_data') }} AS sales
)

-- building_id needs the coded columns above, so it's added here (see the building_id macro).
SELECT
    *,
    {{ building_id() }} AS building_id
FROM coded
