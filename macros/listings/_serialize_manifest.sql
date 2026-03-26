{% macro _serialize_manifest(manifest_dict) %}
    {#
        Converts a listing_manifest config dict into a YAML string suitable for
        embedding in CREATE/ALTER listing statements (organization or external)
        via the AS $$ ... $$ syntax.

        Handles nested dicts, lists, and scalar values.
        Produces clean YAML output without Python-style representations.
    #}
    {% set lines = [] %}
    {{ dbt_snowflake_listings._serialize_yaml_node(manifest_dict, lines, 0) }}
    {{ return(lines | join('\n')) }}
{% endmacro %}


{% macro _serialize_yaml_node(node, lines, indent) %}
    {% set prefix = ' ' * indent %}

    {% if node is mapping %}
        {% for key, value in node.items() %}
            {% if value is mapping %}
                {% do lines.append(prefix ~ key ~ ':') %}
                {{ dbt_snowflake_listings._serialize_yaml_node(value, lines, indent + 2) }}
            {% elif value is iterable and value is not string %}
                {% do lines.append(prefix ~ key ~ ':') %}
                {% for item in value %}
                    {% if item is mapping %}
                        {# First key of the dict goes on the same line as the dash #}
                        {% set item_keys = item.keys() | list %}
                        {% if item_keys | length > 0 %}
                            {% set first_key = item_keys[0] %}
                            {% set first_val = item[first_key] %}
                            {% if first_val is mapping or (first_val is iterable and first_val is not string) %}
                                {% do lines.append(prefix ~ '  - ' ~ first_key ~ ':') %}
                                {{ dbt_snowflake_listings._serialize_yaml_node(first_val, lines, indent + 6) }}
                            {% else %}
                                {% do lines.append(prefix ~ '  - ' ~ first_key ~ ': ' ~ dbt_snowflake_listings._yaml_scalar(first_val)) %}
                            {% endif %}
                            {# Remaining keys at increased indent #}
                            {% for remaining_key in item_keys[1:] %}
                                {% set remaining_val = item[remaining_key] %}
                                {% if remaining_val is mapping %}
                                    {% do lines.append(prefix ~ '    ' ~ remaining_key ~ ':') %}
                                    {{ dbt_snowflake_listings._serialize_yaml_node(remaining_val, lines, indent + 6) }}
                                {% elif remaining_val is iterable and remaining_val is not string %}
                                    {% do lines.append(prefix ~ '    ' ~ remaining_key ~ ':') %}
                                    {{ dbt_snowflake_listings._serialize_yaml_node({remaining_key: remaining_val}, lines, indent + 4) }}
                                {% else %}
                                    {% do lines.append(prefix ~ '    ' ~ remaining_key ~ ': ' ~ dbt_snowflake_listings._yaml_scalar(remaining_val)) %}
                                {% endif %}
                            {% endfor %}
                        {% endif %}
                    {% else %}
                        {% do lines.append(prefix ~ '  - ' ~ dbt_snowflake_listings._yaml_scalar(item)) %}
                    {% endif %}
                {% endfor %}
            {% else %}
                {% do lines.append(prefix ~ key ~ ': ' ~ dbt_snowflake_listings._yaml_scalar(value)) %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}


{% macro _yaml_scalar(value) %}
    {#
        Formats a scalar value for YAML output.
        Strings containing special chars or looking like non-strings get quoted.
    #}
    {% if value is none %}
        {{- return('null') -}}
    {% elif value is boolean %}
        {{- return('true' if value else 'false') -}}
    {% elif value is number %}
        {{- return(value | string) -}}
    {% elif value is string %}
        {# Quote strings that contain YAML-special characters or could be misinterpreted #}
        {% if ':' in value or '#' in value or '{' in value or '}' in value
           or '[' in value or ']' in value or ',' in value or '&' in value
           or '*' in value or '!' in value or '|' in value or '>' in value
           or "'" in value or '%' in value or '@' in value
           or value | lower in ('true', 'false', 'yes', 'no', 'null', 'on', 'off')
           or value != value | trim
           or value == '' %}
            {{- return('"' ~ value | replace('\\', '\\\\') | replace('"', '\\"') ~ '"') -}}
        {% else %}
            {{- return(value) -}}
        {% endif %}
    {% else %}
        {{- return('"' ~ value | string ~ '"') -}}
    {% endif %}
{% endmacro %}
