{% macro _resolve_object_type(database, schema, name) %}
    {#
        Resolves the Snowflake object type by cascading through metadata sources.
        Returns one of: 'TABLE', 'VIEW', 'SEMANTIC_VIEW', 'CORTEX_SEARCH_SERVICE'.
        Raises an error if the object cannot be found in any catalog.
        Uppercases all identifiers for Snowflake compatibility.
    #}
    {% set db = database | upper %}
    {% set sch = schema | upper %}
    {% set obj = name | upper %}
    {% set fqn = db ~ '.' ~ sch ~ '.' ~ obj %}

    {# ── 1. Check INFORMATION_SCHEMA.TABLES (tables, views, materialized views) ── #}
    {% set query %}
        SELECT TABLE_TYPE
        FROM {{ db }}.INFORMATION_SCHEMA.TABLES
        WHERE TABLE_CATALOG = '{{ db }}'
          AND TABLE_SCHEMA = '{{ sch }}'
          AND TABLE_NAME = '{{ obj }}'
    {% endset %}

    {% set result = run_query(query) %}

    {% if result | length > 0 %}
        {% set table_type = result.columns[0].values()[0] %}
        {% if table_type in ('VIEW', 'MATERIALIZED VIEW') %}
            {{ return('VIEW') }}
        {% else %}
            {{ return('TABLE') }}
        {% endif %}
    {% endif %}

    {# ── 2. Check for Semantic View ── #}
    {% set sv_query %}
        SHOW SEMANTIC VIEWS LIKE '{{ obj }}' IN SCHEMA {{ db }}.{{ sch }}
    {% endset %}

    {% set sv_result = run_query(sv_query) %}

    {% if sv_result | length > 0 %}
        {{ return('SEMANTIC_VIEW') }}
    {% endif %}

    {# ── 3. Check for Cortex Search Service ── #}
    {% set css_query %}
        SHOW CORTEX SEARCH SERVICES LIKE '{{ obj }}' IN SCHEMA {{ db }}.{{ sch }}
    {% endset %}

    {% set css_result = run_query(css_query) %}

    {% if css_result | length > 0 %}
        {{ return('CORTEX_SEARCH_SERVICE') }}
    {% endif %}

    {# ── 4. Not found anywhere ── #}
    {{ exceptions.raise_compiler_error(
        "Object " ~ fqn ~ " not found in INFORMATION_SCHEMA.TABLES, "
        "SEMANTIC VIEWS, or CORTEX SEARCH SERVICES. "
        "Ensure it exists before creating the listing."
    ) }}
{% endmacro %}
