{{
    config(
        materialized='table',
        tags=['marts', 'bridge']
    )
}}

-- One row per recorded sale document: its sale_id and the book and page it stands for.
-- The facts and dim_sales_groups key on sale_id, so join here for book and pg.
SELECT
    sale_id,
    book,
    pg
FROM {{ ref('int_sales') }}
