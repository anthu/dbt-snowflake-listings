{% macro _drop_share(share_name) %}
    {{ dbt_snowflake_listings._log_action('DROP', 'SHARE', share_name) }}

    {% call statement('drop_share', fetch_result=false) %}
        DROP SHARE IF EXISTS {{ share_name }}
    {% endcall %}
{% endmacro %}
