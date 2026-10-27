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
            -- Totals become NULL when every part is present and they don't add up.
            -- With a missing part the comparison is NULL, so the total is kept.
            IF(sales.total_full != sales.land_full + sales.bldg_full, NULL, sales.total_full) AS total_full,
            IF(sales.total_living_area != sales.main_living_area + sales.upper_living_area + sales.fin_attic_area, NULL, sales.total_living_area) AS total_living_area,
            IF(sales.fin_bsmt_area_tot != sales.fin_bsmt_area1 + sales.fin_bsmt_area2, NULL, sales.fin_bsmt_area_tot) AS fin_bsmt_area_tot,

            -- Years that aren't 4 digits (e.g. the 0 placeholders) become NULL
            IF(sales.year_built BETWEEN 1000 AND 9999, sales.year_built, NULL) AS year_built,
            IF(sales.year_remodel BETWEEN 1000 AND 9999, sales.year_remodel, NULL) AS year_remodel,
            IF(sales.eff_year_built BETWEEN 1000 AND 9999, sales.eff_year_built, NULL) AS eff_year_built,
            IF(sales.condo_year_built BETWEEN 1000 AND 9999, sales.condo_year_built, NULL) AS condo_year_built,
            IF(sales.yr BETWEEN 1000 AND 9999, sales.yr, NULL) AS yr
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

-- sale_id is book and pg as one number, for tools that join on a single column (see the sale_id macro).
-- building_id needs the coded columns above, so it's added here (see the building_id macro).
-- The group IDs key the parcels the sale lists into bridge_dp_groups and bridge_gp_groups
-- (see the parcel_groups macros). dps and gps stay, because the bridges are built from them.
SELECT
    *,
    {{ sale_id('book', 'pg') }} AS sale_id,
    {{ building_id() }} AS building_id,
    {{ group_id(listed_dps('dps')) }} AS dp_group_id,
    {{ group_id(listed_gps('gps')) }} AS gp_group_id,
    ARRAY_LENGTH({{ listed_dps('dps') }}) AS dp_count
FROM coded
