{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per recorded sale document, with what describes the sale as a whole rather than
-- measures it: the book and page, the document type, the sale conditions, the parties and the
-- detached structures. Both facts key on sale_id and reference this table.
SELECT
    -- Keys
    sale_id,
    book,
    pg,

    -- Sale
    instrument_id,
    quality1_id,
    quality2_id,
    analysis_quality_id,
    buyer,
    seller,

    -- Detached structures
    detached_structs
FROM {{ ref('int_sales') }}
