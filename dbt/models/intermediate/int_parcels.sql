{{
    config(
        materialized='table',
        tags=['intermediate']
    )
}}

WITH duplicates AS (
    SELECT
        dp,
        NULLIF(TRIM(gp), '') AS gp,
        NULLIF(TRIM(jurisdiction), '') AS jurisdiction,
        NULLIF(TRIM(nbhd), '') AS nbhd,
        NULLIF(TRIM(pocket), '') AS pocket,
        NULLIF(TRIM(school_district), '') AS school_district,

        -- Set zip to NULL if invalid
        IF(REGEXP_CONTAINS(zip, r'^[0-9]{5}$'), zip, NULL) AS zip,

        NULLIF(TRIM(address), '') AS address,
        NULLIF(TRIM(platname), '') AS platname,        
        ROW_NUMBER() OVER (PARTITION BY dp ORDER BY sale_date DESC, book DESC, pg DESC) AS priority
    FROM {{ ref('stg_sale_data') }}
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
    ANY_VALUE(platname HAVING MIN priority) AS platname,
FROM duplicates
GROUP BY dp
ORDER BY dp