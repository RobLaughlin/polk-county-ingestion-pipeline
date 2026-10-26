{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per calendar day, from the earliest to the latest sale or entry date.
-- Days with no sales are included, so time series show them as zero.
-- Built from int_sales, not fct_sales_groups, because fct_sales_groups references this model.
WITH all_dates AS (
    SELECT sale_date AS date_day FROM {{ ref('int_sales') }}
    UNION ALL
    SELECT initial_entry_date FROM {{ ref('int_sales') }}
),

bounds AS (
    SELECT
        MIN(date_day) AS first_day,
        MAX(date_day) AS last_day
    FROM all_dates
)

SELECT
    date_day,
    EXTRACT(YEAR FROM date_day) AS year,
    EXTRACT(QUARTER FROM date_day) AS quarter,
    EXTRACT(MONTH FROM date_day) AS month,
    FORMAT_DATE('%B', date_day) AS month_name,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    FORMAT_DATE('%A', date_day) AS day_of_week_name,
    EXTRACT(ISOWEEK FROM date_day) AS iso_week,
    EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) AS is_weekend
FROM bounds, UNNEST(GENERATE_DATE_ARRAY(first_day, last_day)) AS date_day
