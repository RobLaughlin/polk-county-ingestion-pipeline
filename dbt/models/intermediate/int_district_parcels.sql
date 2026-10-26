{{
    config(
        materialized='table',
        tags=['intermediate', 'parcels']
    )
}}

-- dp_short is dp in the short form dps uses (see the short_dp macro).
SELECT
    parcels.dp,
    {{ short_dp('parcels.dp') }} AS dp_short,
    parcels.* EXCEPT (dp, school_district)
    REPLACE (
        -- Set zip to NULL if invalid
        IF(REGEXP_CONTAINS(parcels.zip, r'^[0-9]{5}$'), parcels.zip, NULL) AS zip
    ),

    {{ lookup_id('parcels.school_district', 'dim_school_districts', 'school_district') }} AS school_district_id
FROM {{ ref('stg_district_parcels') }} AS parcels
