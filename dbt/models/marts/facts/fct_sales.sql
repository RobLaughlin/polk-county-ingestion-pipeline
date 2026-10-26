{{
    config(
        materialized='table',
        tags=['marts', 'facts']
    )
}}

-- One row per recorded sale document, with the measurements of the property as it was sold.
-- Descriptive building data lives in dim_buildings (joined on building_id).
SELECT
    -- Keys
    book,
    pg,
    dp,
    building_id,

    -- Sale
    sale_date,
    initial_entry_date,
    price AS price_dollars,
    seller,
    buyer,
    dps,
    gps,
    instrument_id,
    quality1_id,
    quality2_id,
    analysis_quality_id,

    -- Assessed values
    land_full AS land_full_assessment_dollars,
    bldg_full AS bldg_full_assessment_dollars,
    total_full AS total_full_assessment_dollars,

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

    -- Land
    land_sf,
    land_acres,

    -- Detached structures (every parcel in the sale)
    detached_structs,

    -- Areas (sq ft)
    main_living_area AS main_living_area_sf,
    upper_living_area AS upper_living_area_sf,
    fin_attic_area AS fin_attic_area_sf,
    total_living_area AS total_living_area_sf,
    unfin_attic_area AS unfin_attic_area_sf,
    att_garage_area AS att_garage_area_sf,
    open_porch_area AS open_porch_area_sf,
    enclose_porch_area AS enclose_porch_area_sf,
    patio_area AS patio_area_sf,
    deck_area AS deck_area_sf,
    canopy_area AS canopy_area_sf,
    veneer_area AS veneer_area_sf,
    carport_area AS carport_area_sf,
    condo_fin_liv_area AS condo_fin_liv_area_sf,

    -- Basement
    basement_area AS basement_area_sf,
    fin_bsmt_area_tot AS fin_bsmt_area_total_sf,
    fin_bsmt_area1 AS fin_bsmt_area1_sf,
    fin_bsmt_area2 AS fin_bsmt_area2_sf,
    bsmt_walkout AS bsmt_walkout_ft,
    bsmt_gar_capacity AS bsmt_garage_stalls
FROM {{ ref('int_sales') }}
