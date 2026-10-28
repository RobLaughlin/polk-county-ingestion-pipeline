{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per recorded sale document, with what describes the sale as a whole rather than
-- measures it: the document type, the sale conditions, the parties and the detached structures.
-- The measures, such as price, are in fct_sales_groups, on the same sale_id.
SELECT
    -- Keys
    sale_id,

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
