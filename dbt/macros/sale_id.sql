{#
    One number for each recorded document: the book, then the page in the last 9 digits,
        book 12345, page 678 -> 12345000000678
    The page must stay below sale_id_pg_limit (int_sales tests it), and INT64 leaves room for
    books up to about 9.2 billion. The limit is fixed rather than taken from the data, so a
    sale's id never changes between builds.
#}
{% macro sale_id_pg_limit() %}
    {{ return(1000000000) }}
{% endmacro %}

{% macro sale_id(book, pg) %}
    {{ book }} * {{ sale_id_pg_limit() }} + {{ pg }}
{% endmacro %}
