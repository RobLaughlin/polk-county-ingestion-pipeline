{{
    config(
        materialized='table',
        tags=['marts', 'bridge']
    )
}}

-- One row per district parcel in each dp group: the parcels a sale lists in dps.
-- Sales that list the same parcels share a group, so each group is stored once.
SELECT DISTINCT
    listed_dp AS dp,
    sales.dp_group_id AS group_id
FROM {{ ref('int_sales') }} AS sales, UNNEST({{ listed_dps('sales.dps') }}) AS listed_dp
ORDER BY group_id, dp
