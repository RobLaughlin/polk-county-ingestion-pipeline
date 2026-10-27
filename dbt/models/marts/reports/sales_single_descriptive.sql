{{
    config(
        materialized='table',
        tags=['marts', 'reports']
    )
}}

SELECT
    -- Keys
    fct_sales.sale_id,
    fct_sales.book,
    fct_sales.pg,
    fct_sales.dp,
    fct_sales.building_id,

    -- Rooms and fixtures
    fct_sales.rooms,
    fct_sales.bathrooms,
    fct_sales.bedrooms,
    fct_sales.toilet_rooms,
    fct_sales.extra_fixtures,
    fct_sales.whirlpools,
    fct_sales.hottubs,
    fct_sales.saunas,
    fct_sales.fireplaces,

    -- Building: codes (from buildings_descriptive)
    buildings.occupancy,
    buildings.residence_type,
    buildings.bldg_style,
    buildings.exterior_wall_type,
    buildings.roof_type,
    buildings.roof_material,
    buildings.foundation,
    buildings.heating,
    buildings.fin_bsmt_qual1,
    buildings.fin_bsmt_qual2,

    -- Building: grade and condition (from buildings_descriptive)
    buildings.grade,
    buildings.grade_adjustment,
    buildings.condition,

    -- Building: units and percentages (from buildings_descriptive)
    buildings.families,
    buildings.brick_pct,
    buildings.air_conditioning_pct,
    buildings.completed_pct,
    buildings.garage_brick_pct,

    -- Building: years (from buildings_descriptive)
    buildings.year_built,
    buildings.eff_year_built,
    buildings.year_remodel,
    buildings.condo_year_built,

    -- Building: when this version was seen (from buildings_descriptive)
    buildings.first_sale_date,
    buildings.last_sale_date,

    -- Areas (sq ft)
    fct_sales.main_living_area_sf,
    fct_sales.upper_living_area_sf,
    fct_sales.fin_attic_area_sf,
    fct_sales.total_living_area_sf,
    fct_sales.unfin_attic_area_sf,
    fct_sales.att_garage_area_sf,
    fct_sales.open_porch_area_sf,
    fct_sales.enclose_porch_area_sf,
    fct_sales.patio_area_sf,
    fct_sales.deck_area_sf,
    fct_sales.canopy_area_sf,
    fct_sales.veneer_area_sf,
    fct_sales.carport_area_sf,
    fct_sales.condo_fin_liv_area_sf,

    -- Basement
    fct_sales.basement_area_sf,
    fct_sales.fin_bsmt_area_total_sf,
    fct_sales.fin_bsmt_area1_sf,
    fct_sales.fin_bsmt_area2_sf,
    fct_sales.bsmt_walkout_ft,
    fct_sales.bsmt_garage_stalls
FROM {{ ref('fct_sales_single') }} AS fct_sales
LEFT JOIN {{ ref('buildings_descriptive') }} AS buildings
ON
    fct_sales.building_id = buildings.building_id
    AND fct_sales.dp = buildings.dp
