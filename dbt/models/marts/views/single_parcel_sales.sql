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
    dim_dp.gp,
    sales_groups.* EXCEPT(dp_count, dp_group_id, gp_group_id, sale_id, book, pg),
    sales_singles.* EXCEPT (sale_id, book, pg, dp)
FROM {{ ref('sales_groups_descriptive') }} AS sales_groups
INNER JOIN {{ ref('sales_single_descriptive') }} AS sales_singles
ON sales_groups.sale_id = sales_singles.sale_id
INNER JOIN {{ ref('dim_district_parcels') }} AS dim_dp
ON dim_dp.dp = sales_singles.dp
WHERE dp_count = 1
