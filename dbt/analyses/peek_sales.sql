SELECT *
FROM {{ ref('sales_preview') }}
LIMIT 10