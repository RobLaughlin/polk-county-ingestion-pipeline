{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per gp group: a set of geoparcels some sale lists in gps, with how many there are.
-- Sales that list the same geoparcels share a group, so each group is stored once.
-- fct_sales_groups.gp_group_id and bridge_gp_groups.group_id both reference it.
SELECT DISTINCT
    gp_group_id AS group_id,
    ARRAY_LENGTH({{ listed_gps('gps') }}) AS gp_count
FROM {{ ref('int_sales') }}
-- A sale with a blank gps lists no geoparcels, so it has no gp group.
WHERE gp_group_id IS NOT NULL
