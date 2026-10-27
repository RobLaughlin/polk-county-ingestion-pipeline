{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

SELECT
    -- Keys
    sale_id,
    book,
    pg,
    fct_sales.dp,
    fct_sales.building_id,

    -- Rooms and fixtures
    rooms,
    bathrooms,
    bedrooms,
    toilet_rooms,
    extra_fixtures,
    whirlpools,
    hottubs,
    saunas,
    fireplaces,
    dim_buildings.* EXCEPT (dp, building_id),

    -- Areas (sq ft)
    main_living_area_sf,
    upper_living_area_sf,
    fin_attic_area_sf,
    total_living_area_sf,
    unfin_attic_area_sf,
    att_garage_area_sf,
    open_porch_area_sf,
    enclose_porch_area_sf,
    patio_area_sf,
    deck_area_sf,
    canopy_area_sf,
    veneer_area_sf,
    carport_area_sf,
    condo_fin_liv_area_sf,

    -- Basement
    basement_area_sf,
    fin_bsmt_area_total_sf,
    fin_bsmt_area1_sf,
    fin_bsmt_area2_sf,
    bsmt_walkout_ft,
    bsmt_garage_stalls

    
FROM {{ ref('fct_sales_single') }} AS fct_sales
LEFT JOIN {{ ref('dim_buildings') }} AS dim_buildings
ON fct_sales.building_id = dim_buildings.building_id
AND fct_sales.dp = dim_buildings.dp
