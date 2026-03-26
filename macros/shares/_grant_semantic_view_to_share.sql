{% macro _grant_semantic_view_to_share(share_name, database, schema, name, granted_tables) %}
    {#
        Grants a semantic view to a share per Snowflake requirements:
        1. GRANT REFERENCES ON SEMANTIC VIEW
        2. GRANT SELECT ON SEMANTIC VIEW
        3. Auto-detect and grant SELECT on underlying tables via DESCRIBE SEMANTIC VIEW

        Args:
            share_name: Name of the share
            database, schema, name: Semantic view identifiers (will be uppercased)
            granted_tables: Mutable list of already-granted table FQNs to avoid duplicates
    #}
    {% set db = database | upper %}
    {% set sch = schema | upper %}
    {% set obj = name | upper %}
    {% set fqn = db ~ '.' ~ sch ~ '.' ~ obj %}

    {{ dbt_snowflake_listings._log_action('GRANT REFERENCES ON SEMANTIC VIEW', fqn, 'TO SHARE ' ~ share_name) }}

    {% call statement('grant_sv_ref_' ~ obj, fetch_result=false) %}
        GRANT REFERENCES ON SEMANTIC VIEW {{ fqn }} TO SHARE {{ share_name }}
    {% endcall %}

    {{ dbt_snowflake_listings._log_action('GRANT SELECT ON SEMANTIC VIEW', fqn, 'TO SHARE ' ~ share_name) }}

    {% call statement('grant_sv_sel_' ~ obj, fetch_result=false) %}
        GRANT SELECT ON SEMANTIC VIEW {{ fqn }} TO SHARE {{ share_name }}
    {% endcall %}

    {# ── Auto-detect underlying tables and grant SELECT on each ── #}
    {% set desc_query %}
        DESCRIBE SEMANTIC VIEW {{ fqn }}
    {% endset %}

    {% set desc_result = run_query(desc_query) %}

    {% if desc_result | length > 0 %}
        {% set col_names = desc_result.column_names | map('upper') | list %}
        {% set kind_idx = -1 %}
        {% set ref_idx = -1 %}

        {% for col in col_names %}
            {% if col == 'KIND' or col == 'kind' %}
                {% set kind_idx = loop.index0 %}
            {% endif %}
            {% if col == 'REF' or col == 'REFERENCING' or col == 'TABLE_NAME' or col == 'ref' or col == 'referencing' or col == 'table_name' %}
                {% set ref_idx = loop.index0 %}
            {% endif %}
        {% endfor %}

        {# Extract referenced tables from DESCRIBE output #}
        {% for row in desc_result.rows %}
            {% set kind = row[0] | upper if row | length > 0 else '' %}
            {% if kind == 'TABLE' %}
                {% set table_ref = row[1] if row | length > 1 else '' %}
                {% if table_ref %}
                    {% set table_fqn = table_ref | upper %}
                    {% set parts = table_fqn.split('.') %}

                    {% if parts | length == 3 and table_fqn not in granted_tables %}
                        {% set tbl_db = parts[0] %}
                        {% set tbl_sch = parts[1] %}
                        {% set tbl_name = parts[2] %}

                        {{ dbt_snowflake_listings._log_action(
                            'GRANT SELECT ON TABLE (semantic view dependency)',
                            table_fqn, 'TO SHARE ' ~ share_name
                        ) }}

                        {% call statement('grant_sv_dep_' ~ tbl_name, fetch_result=false) %}
                            GRANT SELECT ON TABLE {{ table_fqn }} TO SHARE {{ share_name }}
                        {% endcall %}

                        {% do granted_tables.append(table_fqn) %}
                    {% endif %}
                {% endif %}
            {% endif %}
        {% endfor %}
    {% endif %}

{% endmacro %}
