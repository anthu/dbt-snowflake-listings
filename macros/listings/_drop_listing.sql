{% macro _drop_listing(listing_name) %}
    {#
        Drops a listing (organization or external). Checks state and only
        unpublishes if the listing is currently published (not DRAFT or
        already UNPUBLISHED). Works for both listing types since DROP LISTING
        and ALTER LISTING ... UNPUBLISH are type-agnostic.
    #}
    {% if dbt_snowflake_listings._listing_exists(listing_name) %}

        {% set show_result = run_query("SHOW LISTINGS LIKE '" ~ listing_name ~ "'") %}
        {% if show_result | length > 0 %}
            {% set state = show_result.columns['state'].values()[0] | default('') | upper %}
            {% if state not in ('DRAFT', 'UNPUBLISHED', '') %}
                {{ dbt_snowflake_listings._log_action('UNPUBLISH', 'LISTING', listing_name) }}
                {% call statement('unpublish_listing', fetch_result=false) %}
                    ALTER LISTING {{ listing_name }} UNPUBLISH
                {% endcall %}
            {% endif %}
        {% endif %}

        {{ dbt_snowflake_listings._log_action('DROP', 'LISTING', listing_name) }}
        {% call statement('drop_listing', fetch_result=false) %}
            DROP LISTING {{ listing_name }}
        {% endcall %}

    {% else %}
        {{ dbt_snowflake_listings._log_action('SKIP DROP', 'LISTING', listing_name, 'does not exist') }}
    {% endif %}
{% endmacro %}
