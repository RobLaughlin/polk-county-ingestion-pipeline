{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per district parcel, with its location as of its most recent sale.
SELECT * FROM {{ ref('int_parcels') }}
