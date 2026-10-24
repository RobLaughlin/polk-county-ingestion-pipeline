{#
    ID of a column's value in a dim_* lookup model, matched on its name column.
    A value missing from the lookup gets the lookup's 'Other' ID, and NULL stays NULL.
    Pass the column with its table alias (e.g. 'sales.roof_type'), because the lookup
    usually has a column with the same name.
#}
{% macro lookup_id(column, dim, name_column) %}
    CASE
        WHEN {{ column }} IS NULL THEN NULL
        ELSE COALESCE(
            (SELECT codes.id FROM {{ ref(dim) }} AS codes WHERE codes.{{ name_column }} = {{ column }}),
            (SELECT codes.id FROM {{ ref(dim) }} AS codes WHERE codes.{{ name_column }} = 'Other')
        )
    END
{% endmacro %}
