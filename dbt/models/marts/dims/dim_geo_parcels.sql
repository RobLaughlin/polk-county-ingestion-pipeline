{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per geoparcel, with its legal description. There's nothing to clean, so like the
-- code lookups it skips intermediate and reads staging directly.
SELECT * FROM {{ ref('stg_geo_parcels') }}
