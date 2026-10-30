-- dp groups whose dp_count isn't the number of parcels bridge_dp_groups lists for them.
SELECT
    dim_dp_groups.group_id,
    dim_dp_groups.dp_count,
    COUNT(bridge_dp_groups.dp) AS bridge_parcels
FROM {{ ref('dim_dp_groups') }} AS dim_dp_groups
LEFT JOIN {{ ref('bridge_dp_groups') }} AS bridge_dp_groups
ON dim_dp_groups.group_id = bridge_dp_groups.group_id
GROUP BY dim_dp_groups.group_id, dim_dp_groups.dp_count
HAVING dim_dp_groups.dp_count != COUNT(bridge_dp_groups.dp)
