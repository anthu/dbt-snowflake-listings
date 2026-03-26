{% macro describe_listing(listing_name) %}
    {#
        Public macro to describe an organization listing.

        Usage:
            dbt run-operation dbt_snowflake_listings.describe_listing \
                --args '{listing_name: MY_LISTING}'
    #}
    {% if not listing_name %}
        {{ exceptions.raise_compiler_error("listing_name is required") }}
    {% endif %}

    {% set query %}
        DESCRIBE LISTING {{ listing_name }}
    {% endset %}

    {% set results = run_query(query) %}

    {% if execute %}
        {% do results.print_table(max_column_width=80) %}
    {% endif %}
{% endmacro %}
