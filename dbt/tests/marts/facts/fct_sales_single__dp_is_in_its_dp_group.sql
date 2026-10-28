{{ config(severity='warn') }}

-- Sales filed under a dp that isn't one of the parcels the sale lists in dps (its dp group).
SELECT
    fct_sales_single.sale_id,
    fct_sales_single.dp,
    fct_sales_groups.dp_group_id
FROM {{ ref('fct_sales_single') }} AS fct_sales_single
INNER JOIN {{ ref('fct_sales_groups') }} AS fct_sales_groups
ON fct_sales_single.sale_id = fct_sales_groups.sale_id
LEFT JOIN {{ ref('bridge_dp_groups') }} AS bridge_dp_groups
ON
    fct_sales_groups.dp_group_id = bridge_dp_groups.group_id
    AND fct_sales_single.dp = bridge_dp_groups.dp
WHERE bridge_dp_groups.dp IS NULL
