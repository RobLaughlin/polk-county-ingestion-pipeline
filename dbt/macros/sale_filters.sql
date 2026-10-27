{#
    The highest price that isn't treated as a market price, in dollars. The Iowa Department of
    Revenue gives a sale of $10,000 or less condition 46 (Under 10000), so is_over_price_floor in
    filtered_single_parcel_sales needs a price above it.
#}
{% macro sale_price_floor() %}
    {{ return(10000) }}
{% endmacro %}
