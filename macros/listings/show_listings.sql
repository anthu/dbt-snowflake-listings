{% macro show_listings(like=none) %}
    {#
        Public macro to show organization listings.

        Usage:
            dbt run-operation dbt_snowflake_listings.show_listings
            dbt run-operation dbt_snowflake_listings.show_listings --args '{like: "MY_%"}'
    #}
    {% set query %}
        SHOW LISTINGS
        {% if like %} LIKE '{{ like }}' {% endif %}
    {% endset %}

    {% set results = run_query(query) %}

    {% if execute %}
        {% do results.print_table(max_column_width=40) %}
    {% endif %}
{% endmacro %}
