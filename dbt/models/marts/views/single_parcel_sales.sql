{{
    config(
        materialized='view',
        tags=['marts', 'views']
    )
}}

SELECT 
    sales_groups.sale_id,
    sales_groups.book,
    sales_groups.pg,
    sales_singles.dp,
    bridge_gp_groups.gp,
    sales_groups.* EXCEPT(dp_count, dp_group_id, gp_group_id, sale_id, book, pg),
    sales_singles.* EXCEPT (sale_id, book, pg, dp)
FROM {{ ref('sales_groups_descriptive') }} AS sales_groups
INNER JOIN {{ ref('sales_single_descriptive') }} AS sales_singles
ON sales_groups.sale_id = sales_singles.sale_id
LEFT JOIN {{ ref('bridge_gp_groups') }} AS bridge_gp_groups
ON sales_groups.gp_group_id = bridge_gp_groups.group_id
WHERE dp_count = 1
