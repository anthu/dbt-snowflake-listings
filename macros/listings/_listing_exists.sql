{% macro _listing_exists(listing_name) %}
    {#
        Checks if an organization listing exists.
        Returns true if found, false otherwise.
    #}
    {% set query %}
        SHOW LISTINGS LIKE '{{ listing_name }}'
    {% endset %}

    {% set result = run_query(query) %}
    {{ return(result | length > 0) }}
{% endmacro %}
