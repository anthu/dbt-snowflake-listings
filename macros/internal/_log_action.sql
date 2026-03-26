{% macro _log_action(action, object_type, object_name, details=none) %}
    {{ log("[dbt_snowflake_listings] " ~ action ~ " " ~ object_type ~ ": " ~ object_name ~ ((" (" ~ details ~ ")") if details else ""), info=true) }}
{% endmacro %}
