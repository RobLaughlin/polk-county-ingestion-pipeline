-- Show all records with duplicate (dp, sale_date) keys.

WITH duplicates AS (
    SELECT dp, sale_date, COUNT(*) AS duplicate_keys
    FROM {{ source('raw', 'sales_raw') }}
    GROUP BY dp, sale_date
    HAVING COUNT(*) > 1
)
SELECT duplicates.duplicate_keys, *  FROM {{ source('raw', 'sales_raw') }}
INNER JOIN duplicates
ON duplicates.dp = sales_raw.dp AND duplicates.sale_date = sales_raw.sale_date
ORDER BY duplicates.duplicate_keys DESC, duplicates.dp, duplicates.sale_date

