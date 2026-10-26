{{
    config(
        materialized='table',
        tags=['intermediate', 'parcels']
    )
}}

-- One row per district parcel: every dp in stg_district_parcels, plus the parcels only ever
-- listed in another sale's dps (see the listed_dps macro). Those have no sale of their own, so
-- only dp and dp_short are set.
-- dp_short is dp in the short form dps uses (see the short_dp macro).
WITH district_parcels AS (
    SELECT dp FROM {{ ref('stg_district_parcels') }}
    UNION DISTINCT
    SELECT listed_dp FROM {{ ref('stg_sale_data') }} AS sales, UNNEST({{ listed_dps('sales.dps') }}) AS listed_dp
)

SELECT
    district_parcels.dp,
    {{ short_dp('district_parcels.dp') }} AS dp_short,
    parcels.* EXCEPT (dp, school_district)
    REPLACE (
        -- Set zip to NULL if invalid
        IF(REGEXP_CONTAINS(parcels.zip, r'^[0-9]{5}$'), parcels.zip, NULL) AS zip
    ),

    {{ lookup_id('parcels.school_district', 'dim_school_districts', 'school_district') }} AS school_district_id
FROM district_parcels
LEFT JOIN {{ ref('stg_district_parcels') }} AS parcels
    ON parcels.dp = district_parcels.dp
