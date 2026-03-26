{% macro _create_share(share_name, share_objects, secure_objects_only=false) %}
    {#
        Creates a share (if not exists) and grants usage on all databases/schemas
        referenced by the share objects, then grants on each object based on its
        resolved type (TABLE, VIEW, SEMANTIC_VIEW, CORTEX_SEARCH_SERVICE).

        Args:
            share_name: Name of the share to create
            share_objects: List of dicts with 'database', 'schema', 'name' keys
            secure_objects_only: Whether the share only contains secure objects
    #}

    {{ dbt_snowflake_listings._log_action('CREATE', 'SHARE', share_name) }}

    {% call statement('create_share', fetch_result=false) %}
        CREATE SHARE IF NOT EXISTS {{ share_name }}
            SECURE_OBJECTS_ONLY = {{ secure_objects_only | upper }}
    {% endcall %}

    {# Collect unique databases and schemas (uppercased for Snowflake) #}
    {% set databases = [] %}
    {% set schemas = [] %}
    {% for obj in share_objects %}
        {% set db = obj['database'] | upper %}
        {% set sch = db ~ '.' ~ (obj['schema'] | upper) %}
        {% if db not in databases %}
            {% do databases.append(db) %}
        {% endif %}
        {% if sch not in schemas %}
            {% do schemas.append(sch) %}
        {% endif %}
    {% endfor %}

    {# Grant USAGE on each unique database #}
    {% for db in databases %}
        {{ dbt_snowflake_listings._log_action('GRANT USAGE ON DATABASE', 'TO SHARE', share_name, db) }}
        {% call statement('grant_db_' ~ loop.index, fetch_result=false) %}
            GRANT USAGE ON DATABASE {{ db }} TO SHARE {{ share_name }}
        {% endcall %}
    {% endfor %}

    {# Grant USAGE on each unique schema #}
    {% for sch in schemas %}
        {{ dbt_snowflake_listings._log_action('GRANT USAGE ON SCHEMA', 'TO SHARE', share_name, sch) }}
        {% call statement('grant_schema_' ~ loop.index, fetch_result=false) %}
            GRANT USAGE ON SCHEMA {{ sch }} TO SHARE {{ share_name }}
        {% endcall %}
    {% endfor %}

    {# Track granted table FQNs to avoid duplicate grants from semantic view dependencies #}
    {% set granted_tables = [] %}

    {# Grant on each object -- type is auto-resolved #}
    {% for obj in share_objects %}
        {{ dbt_snowflake_listings._grant_to_share(
            share_name,
            obj['database'],
            obj['schema'],
            obj['name'],
            granted_tables
        ) }}
    {% endfor %}

{% endmacro %}
