{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per dp group: a set of district parcels some sale lists in dps, with how many there are.
-- Sales that list the same parcels share a group, so each group is stored once.
-- fct_sales_groups.dp_group_id and bridge_dp_groups.group_id both reference it.
SELECT DISTINCT
    dp_group_id AS group_id,
    dp_count
FROM {{ ref('int_sales') }}
