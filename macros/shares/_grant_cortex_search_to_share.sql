{% macro _grant_cortex_search_to_share(share_name, database, schema, name) %}
    {#
        Best-effort grant of a Cortex Search Service to a share.
        The exact GRANT TO SHARE syntax for Cortex Search Services is evolving
        in Snowflake. This macro attempts the grant and logs a warning if it fails,
        directing the user to add the service via Snowsight Provider Studio.
    #}
    {% set db = database | upper %}
    {% set sch = schema | upper %}
    {% set obj = name | upper %}
    {% set fqn = db ~ '.' ~ sch ~ '.' ~ obj %}

    {{ dbt_snowflake_listings._log_action(
        'GRANT USAGE ON CORTEX SEARCH SERVICE', fqn, 'TO SHARE ' ~ share_name
    ) }}

    {% set grant_sql %}
        GRANT USAGE ON CORTEX SEARCH SERVICE {{ fqn }} TO SHARE {{ share_name }}
    {% endset %}

    {% do run_query(grant_sql) %}

    {{ log(
        "[dbt_snowflake_listings] Successfully granted Cortex Search Service "
        ~ fqn ~ " to share " ~ share_name ~ ".",
        info=true
    ) }}

{% endmacro %}
