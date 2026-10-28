{{
    config(
        materialized='table',
        tags=['staging', 'parcels']
    )
}}

-- One row per geoparcel named anywhere in the export: in gp, gps or legal_all_parcels.
-- legal_all_parcels holds one 'gp: description' entry per parcel, separated by ###.
-- Each parcel keeps the description from the most recent sale that lists it.
-- Strings are trimmed on both sides, and empty strings become NULL.
WITH sales AS (
    SELECT
        CAST(sale_date AS DATE) AS sale_date,
        CAST(book AS INT64) AS book,
        CAST(pg AS INT64) AS pg,
        NULLIF(TRIM(gp), '') AS gp,
        NULLIF(TRIM(gps), '') AS gps,
        NULLIF(TRIM(legal_all_parcels), '') AS legal_all_parcels
    FROM {{ source('raw', 'sales_raw') }}
),

legal_entries AS (
    SELECT
        sales.sale_date,
        sales.book,
        sales.pg,
        REGEXP_EXTRACT(entry, r'^\s*([0-9]{12}):') AS gp,
        NULLIF(TRIM(REGEXP_EXTRACT(entry, r'(?s)^\s*[0-9]{12}:(.*)$')), '') AS parcel_description
    FROM sales, UNNEST(SPLIT(sales.legal_all_parcels, '###')) AS entry
),

descriptions AS (
    SELECT
        gp,
        parcel_description,
        ROW_NUMBER() OVER (
            PARTITION BY gp
            ORDER BY sale_date DESC, book DESC, pg DESC
        ) AS priority
    FROM legal_entries
),

geo_parcels AS (
    SELECT gp FROM sales
    WHERE gp IS NOT NULL
    UNION DISTINCT
    SELECT listed_gp FROM sales, UNNEST({{ listed_gps('sales.gps') }}) AS listed_gp
    UNION DISTINCT
    SELECT gp FROM legal_entries
)

SELECT
    geo_parcels.gp,
    descriptions.parcel_description
FROM geo_parcels
LEFT JOIN descriptions
ON
    geo_parcels.gp = descriptions.gp
    AND descriptions.priority = 1
