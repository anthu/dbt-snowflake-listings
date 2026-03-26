{% macro drop_listing(listing_name, drop_share=none) %}
    {#
        Public macro for tearing down a listing via dbt run-operation.

        Usage:
            dbt run-operation dbt_snowflake_listings.drop_listing \
                --args '{listing_name: MY_LISTING}'

            dbt run-operation dbt_snowflake_listings.drop_listing \
                --args '{listing_name: MY_LISTING, drop_share: MY_SHARE}'
    #}
    {% if not listing_name %}
        {{ exceptions.raise_compiler_error("listing_name is required") }}
    {% endif %}

    {{ dbt_snowflake_listings._drop_listing(listing_name) }}

    {% if drop_share %}
        {{ dbt_snowflake_listings._drop_share(drop_share) }}
    {% endif %}
{% endmacro %}
