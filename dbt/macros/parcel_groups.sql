{#
    The parcels a sale lists in dps or gps, as a sorted array with no repeats or blank entries.
    The order of the lists isn't reliable, so the parcels are always sorted here.
    listed_dps turns each short-form entry into its 14-digit dp (see the long_dp macro).
#}
{% macro listed_dps(dps) %}
    ARRAY(
        SELECT DISTINCT {{ long_dp('TRIM(entry)') }} AS parcel
        FROM UNNEST(SPLIT({{ dps }}, ',')) AS entry
        WHERE TRIM(entry) != ''
        ORDER BY parcel
    )
{% endmacro %}

{% macro listed_gps(gps) %}
    ARRAY(
        SELECT DISTINCT TRIM(entry) AS parcel
        FROM UNNEST(SPLIT({{ gps }}, ',')) AS entry
        WHERE TRIM(entry) != ''
        ORDER BY parcel
    )
{% endmacro %}


{#
    A key for one group of parcels: a hash of the sorted array from listed_dps or listed_gps.
    The same parcels always give the same key, so sales that list the same parcels share a group.
    It's NULL when the list is empty.
#}
{% macro group_id(parcels) %}
    TO_HEX(MD5(NULLIF(ARRAY_TO_STRING({{ parcels }}, ','), '')))
{% endmacro %}
