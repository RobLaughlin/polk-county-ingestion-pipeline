{{ 
    config(
        materialized='table',
        tags=['raw', 'test']
    )
}}

{% set columns = adapter.get_columns_in_relation(source('raw', 'sales_raw')) %}
{% for col in columns %}
SELECT
    '{{ col.name }}' AS column_name,
    COUNTIF({{ col.name }} IS NULL) AS null_count,
    COUNTIF({{ col.name }} IS NOT NULL) AS non_null_count,
    ROUND(100 * safe_divide(COUNTIF({{ col.name }} IS NULL), COUNT(*)), 4) AS null_pct
FROM {{ source('raw', 'sales_raw') }}
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
ORDER BY null_count DESC
