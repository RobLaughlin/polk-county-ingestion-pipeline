{{
    config(
        materialized='table',
        tags=['staging', 'parcels']
    )
}}

-- One row per district parcel, using the values from its most recent sale.
-- Strings are trimmed on both sides, and empty strings become NULL.
-- sale_date, book and pg are strings in raw, so they're cast before sorting.
WITH duplicates AS (
    SELECT
        NULLIF(TRIM(dp), '') AS dp,
        NULLIF(TRIM(gp), '') AS gp,
        NULLIF(TRIM(jurisdiction), '') AS jurisdiction,
        NULLIF(TRIM(nbhd), '') AS nbhd,
        NULLIF(TRIM(pocket), '') AS pocket,
        NULLIF(TRIM(school_district), '') AS school_district,
        NULLIF(TRIM(zip), '') AS zip,
        NULLIF(TRIM(address), '') AS address,
        NULLIF(TRIM(platname), '') AS platname,
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(dp), '')
            ORDER BY CAST(sale_date AS DATE) DESC, CAST(book AS INT64) DESC, CAST(pg AS INT64) DESC
        ) AS priority
    FROM {{ source('raw', 'sales_raw') }}
)

SELECT
    dp,
    ANY_VALUE(gp HAVING MIN priority) AS gp,
    ANY_VALUE(jurisdiction HAVING MIN priority) AS jurisdiction,
    ANY_VALUE(zip HAVING MIN priority) AS zip,
    ANY_VALUE(nbhd HAVING MIN priority) AS nbhd,
    ANY_VALUE(pocket HAVING MIN priority) AS pocket,
    ANY_VALUE(address HAVING MIN priority) AS address,
    ANY_VALUE(school_district HAVING MIN priority) AS school_district,
    ANY_VALUE(platname HAVING MIN priority) AS platname
FROM duplicates
GROUP BY dp
