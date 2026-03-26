{% macro _grant_to_share(share_name, database, schema, name, granted_tables) %}
    {#
        Resolves the object type and dispatches to the appropriate grant macro.
        Handles TABLE, VIEW, SEMANTIC_VIEW, and CORTEX_SEARCH_SERVICE.

        Args:
            share_name: Name of the share
            database, schema, name: Object identifiers
            granted_tables: Mutable list of already-granted table FQNs (for dedup with semantic view deps)
    #}
    {% set db = database | upper %}
    {% set sch = schema | upper %}
    {% set obj = name | upper %}
    {% set object_type = dbt_snowflake_listings._resolve_object_type(db, sch, obj) %}
    {% set fqn = db ~ '.' ~ sch ~ '.' ~ obj %}

    {% if object_type == 'SEMANTIC_VIEW' %}

        {{ dbt_snowflake_listings._grant_semantic_view_to_share(
            share_name, db, sch, obj, granted_tables
        ) }}

    {% elif object_type == 'CORTEX_SEARCH_SERVICE' %}

        {{ dbt_snowflake_listings._grant_cortex_search_to_share(
            share_name, db, sch, obj
        ) }}

    {% else %}

        {# TABLE or VIEW -- skip if already granted as a semantic view dependency #}
        {% if fqn not in granted_tables %}
            {{ dbt_snowflake_listings._log_action('GRANT SELECT ON ' ~ object_type, fqn, 'TO SHARE ' ~ share_name) }}

            {% call statement('grant_' ~ obj, fetch_result=false) %}
                GRANT SELECT ON {{ object_type }} {{ fqn }} TO SHARE {{ share_name }}
            {% endcall %}

            {% do granted_tables.append(fqn) %}
        {% else %}
            {{ dbt_snowflake_listings._log_action('SKIP (already granted)', fqn, 'TO SHARE ' ~ share_name) }}
        {% endif %}

    {% endif %}
{% endmacro %}
