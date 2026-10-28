{{
    config(
        materialized='table',
        tags=['marts', 'facts']
    )
}}

-- One row per recorded sale document, with what the sale covers as a whole: every parcel it lists.
-- On the same sale_id, book and pg are in bridge_sales, the document type, conditions, parties and
-- detached structures in dim_sales_groups, and the residence on dp in fct_sales_single.
SELECT
    -- Keys
    sale_id,
    dp_group_id,
    gp_group_id,
    dp_count,

    -- Sale
    sale_date,
    initial_entry_date,
    price AS price_dollars,

    -- Assessed values
    land_full AS land_full_assessment_dollars,
    bldg_full AS bldg_full_assessment_dollars,
    total_full AS total_full_assessment_dollars,

    -- Land
    land_sf,
    land_acres
FROM {{ ref('int_sales') }}
