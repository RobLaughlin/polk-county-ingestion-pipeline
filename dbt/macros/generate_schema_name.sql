{#
    Use a model's +schema (set per folder in dbt_project.yml) as its dataset name as-is,
    e.g. 'marts_dims', instead of dbt's default '<profile dataset>_marts_dims'.
    Anything without a +schema still goes to the profile's dataset.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
