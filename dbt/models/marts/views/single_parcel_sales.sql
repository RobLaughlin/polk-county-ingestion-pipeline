{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

SELECT
    -- Keys
    sales_groups.sale_id,
    sales_groups.book,
    sales_groups.pg,
    sales_singles.dp,
    bridge_gp_groups.gp,

    -- Sale
    sales_groups.sale_date,
    sales_groups.initial_entry_date,
    sales_groups.price_dollars,
    sales_groups.seller,
    sales_groups.buyer,
    sales_groups.instrument,
    sales_groups.quality1,
    sales_groups.quality2,
    sales_groups.analysis_quality,

    -- Assessed values
    sales_groups.land_full_assessment_dollars,
    sales_groups.bldg_full_assessment_dollars,
    sales_groups.total_full_assessment_dollars,

    -- Land
    sales_groups.land_sf,
    sales_groups.land_acres,

    -- Detached structures
    sales_groups.detached_structs,

    -- Building key
    sales_singles.building_id,

    -- Rooms and fixtures
    sales_singles.rooms,
    sales_singles.bathrooms,
    sales_singles.bedrooms,
    sales_singles.toilet_rooms,
    sales_singles.extra_fixtures,
    sales_singles.whirlpools,
    sales_singles.hottubs,
    sales_singles.saunas,
    sales_singles.fireplaces,

    -- Building (from buildings_descriptive)
    sales_singles.occupancy,
    sales_singles.residence_type,
    sales_singles.bldg_style,
    sales_singles.exterior_wall_type,
    sales_singles.roof_type,
    sales_singles.roof_material,
    sales_singles.foundation,
    sales_singles.heating,
    sales_singles.fin_bsmt_qual1,
    sales_singles.fin_bsmt_qual2,
    sales_singles.grade,
    sales_singles.grade_adjustment,
    sales_singles.condition,
    sales_singles.families,
    sales_singles.brick_pct,
    sales_singles.air_conditioning_pct,
    sales_singles.completed_pct,
    sales_singles.garage_brick_pct,
    sales_singles.year_built,
    sales_singles.eff_year_built,
    sales_singles.year_remodel,
    sales_singles.condo_year_built,
    sales_singles.first_sale_date,
    sales_singles.last_sale_date,

    -- Areas (sq ft)
    sales_singles.main_living_area_sf,
    sales_singles.upper_living_area_sf,
    sales_singles.fin_attic_area_sf,
    sales_singles.total_living_area_sf,
    sales_singles.unfin_attic_area_sf,
    sales_singles.att_garage_area_sf,
    sales_singles.open_porch_area_sf,
    sales_singles.enclose_porch_area_sf,
    sales_singles.patio_area_sf,
    sales_singles.deck_area_sf,
    sales_singles.canopy_area_sf,
    sales_singles.veneer_area_sf,
    sales_singles.carport_area_sf,
    sales_singles.condo_fin_liv_area_sf,

    -- Basement
    sales_singles.basement_area_sf,
    sales_singles.fin_bsmt_area_total_sf,
    sales_singles.fin_bsmt_area1_sf,
    sales_singles.fin_bsmt_area2_sf,
    sales_singles.bsmt_walkout_ft,
    sales_singles.bsmt_garage_stalls
FROM {{ ref('sales_groups_descriptive') }} AS sales_groups
INNER JOIN {{ ref('sales_single_descriptive') }} AS sales_singles
ON sales_groups.sale_id = sales_singles.sale_id
LEFT JOIN {{ ref('bridge_gp_groups') }} AS bridge_gp_groups
ON sales_groups.gp_group_id = bridge_gp_groups.group_id
WHERE sales_groups.dp_count = 1
ORDER BY sales_groups.sale_date DESC
