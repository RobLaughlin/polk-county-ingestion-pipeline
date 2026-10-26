{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per district parcel, with its location as of its most recent sale.
-- Parcels only listed in another sale's dps have just dp and dp_short.
SELECT * FROM {{ ref('int_district_parcels') }}
