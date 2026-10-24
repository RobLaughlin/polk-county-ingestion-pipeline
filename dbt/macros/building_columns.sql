{# The columns that define a building version: what dim_buildings stores and building_id hashes. #}

{% macro building_columns() %}
    {{ return([
        'occupancy_id',
        'residence_type_id',
        'bldg_style_id',
        'exterior_wall_type_id',
        'roof_type_id',
        'roof_material_id',
        'foundation_id',
        'heating_id',
        'fin_bsmt_qual1_id',
        'fin_bsmt_qual2_id',
        'condition_id',
        'grade_id',
        'grade_adjustment',
        'families',
        'percent_brick',
        'air_conditioning',
        'percent_complete',
        'garage_brick',
        'year_built',
        'year_remodel',
        'eff_year_built',
        'condo_year_built',
        'detached_structs'
    ]) }}
{% endmacro %}


{#
    A key for one version of the building on a parcel: a hash of dp plus every building column.
    The same building data always gives the same key, so it's stable across rebuilds.
    It's NULL when a sale has no building data at all (no residence record).
#}
{% macro building_id() %}
    IF(
        COALESCE(
            {%- for col in building_columns() %}
            CAST({{ col }} AS STRING){{ "," if not loop.last }}
            {%- endfor %}
        ) IS NULL,
        NULL,
        {{ dbt_utils.generate_surrogate_key(['dp'] + building_columns()) }}
    )
{% endmacro %}
