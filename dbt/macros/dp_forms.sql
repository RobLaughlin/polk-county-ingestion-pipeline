{#
    The short form of a 14-digit dp, the way dps lists parcels: the 3-digit district, a slash,
    then the three parcel parts without leading zeros, joined by dashes. Trailing parts that are
    0 are left off, but a 0 in the middle is kept:
        18101588000000 -> 181/1588
        02000000019000 -> 020/0-19
        17000370000379 -> 170/370-0-379
    Anything that isn't 14 digits gives NULL.
#}
{% macro short_dp(dp) %}
    {%- set district = "SUBSTR(" ~ dp ~ ", 1, 3)" -%}
    {%- set part1 = "CAST(SAFE_CAST(SUBSTR(" ~ dp ~ ", 4, 5) AS INT64) AS STRING)" -%}
    {%- set part2 = "CAST(SAFE_CAST(SUBSTR(" ~ dp ~ ", 9, 3) AS INT64) AS STRING)" -%}
    {%- set part3 = "CAST(SAFE_CAST(SUBSTR(" ~ dp ~ ", 12, 3) AS INT64) AS STRING)" -%}
    IF(
        REGEXP_CONTAINS({{ dp }}, r'^[0-9]{14}$'),
        CONCAT(
            {{ district }}, '/', {{ part1 }},
            CASE
                WHEN {{ part3 }} != '0' THEN CONCAT('-', {{ part2 }}, '-', {{ part3 }})
                WHEN {{ part2 }} != '0' THEN CONCAT('-', {{ part2 }})
                ELSE ''
            END
        ),
        NULL
    )
{% endmacro %}


{#
    The 14-digit dp of a short-form parcel from dps: the district, then each part padded with
    leading zeros to 5, 3 and 3 digits. A part the short form leaves off is 0:
        181/1588      -> 18101588000000
        020/0-19      -> 02000000019000
        170/370-0-379 -> 17000370000379
    Anything that isn't in the short form gives NULL, so a part that's too long is never cut off.
#}
{% macro long_dp(dp_short) %}
    IF(
        REGEXP_CONTAINS({{ dp_short }}, r'^[0-9]{3}/[0-9]{1,5}(-[0-9]{1,3}){0,2}$'),
        CONCAT(
            REGEXP_EXTRACT({{ dp_short }}, r'^([0-9]{3})/'),
            LPAD(REGEXP_EXTRACT({{ dp_short }}, r'/([0-9]+)'), 5, '0'),
            LPAD(IFNULL(REGEXP_EXTRACT({{ dp_short }}, r'/[0-9]+-([0-9]+)'), '0'), 3, '0'),
            LPAD(IFNULL(REGEXP_EXTRACT({{ dp_short }}, r'/[0-9]+-[0-9]+-([0-9]+)'), '0'), 3, '0')
        ),
        NULL
    )
{% endmacro %}
