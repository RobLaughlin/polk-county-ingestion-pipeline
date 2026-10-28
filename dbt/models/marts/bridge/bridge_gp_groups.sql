{{
    config(
        materialized='table',
        tags=['marts', 'bridge']
    )
}}

-- One row per geoparcel in each gp group: the parcels a sale lists in gps.
-- Sales that list the same parcels share a group, so each group is stored once.
-- A sale with a blank gps lists nothing, so it adds no rows.
SELECT DISTINCT
    listed_gp AS gp,
    sales.gp_group_id AS group_id
FROM {{ ref('int_sales') }} AS sales, UNNEST({{ listed_gps('sales.gps') }}) AS listed_gp
