-- gp groups whose gp_count isn't the number of geoparcels bridge_gp_groups lists for them.
SELECT
    dim_gp_groups.group_id,
    dim_gp_groups.gp_count,
    COUNT(bridge_gp_groups.gp) AS bridge_geoparcels
FROM {{ ref('dim_gp_groups') }} AS dim_gp_groups
LEFT JOIN {{ ref('bridge_gp_groups') }} AS bridge_gp_groups
ON dim_gp_groups.group_id = bridge_gp_groups.group_id
GROUP BY dim_gp_groups.group_id, dim_gp_groups.gp_count
HAVING dim_gp_groups.gp_count != COUNT(bridge_gp_groups.gp)
