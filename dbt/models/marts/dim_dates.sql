{{
    config(
        materialized='table',
        tags=['marts', 'dims']
    )
}}

-- One row per calendar day, from the first year of the sales export to the end of this year.
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
FROM UNNEST(GENERATE_DATE_ARRAY(DATE '1990-01-01', LAST_DAY(CURRENT_DATE(), YEAR))) AS date_day
