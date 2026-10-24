{{
    config(
        materialized='table',
        tags=['intermediate']
    )
}}

SELECT
    parcels.* EXCEPT (school_district)
    REPLACE (
        -- Set zip to NULL if invalid
        IF(REGEXP_CONTAINS(parcels.zip, r'^[0-9]{5}$'), parcels.zip, NULL) AS zip
    ),

    {{ lookup_id('parcels.school_district', 'dim_school_districts', 'school_district') }} AS school_district_id
FROM {{ ref('stg_parcels') }} AS parcels
