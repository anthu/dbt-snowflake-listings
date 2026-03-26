{% macro _parse_share_objects(compiled_sql) %}
    {#
        Parses compiled model SQL for SHARE_OBJECT lines emitted by share_object()/share_objects().
        Returns a list of dicts: [{'database': '...', 'schema': '...', 'name': '...'}, ...]
    #}
    {% set objects = [] %}
    {% for line in compiled_sql.split('\n') %}
        {% set trimmed = line.strip() %}
        {% if trimmed.startswith('-- SHARE_OBJECT|') %}
            {% set parts = trimmed.replace('-- SHARE_OBJECT|', '').split('|') %}
            {% if parts | length == 3 %}
                {% do objects.append({
                    'database': parts[0].strip(),
                    'schema': parts[1].strip(),
                    'name': parts[2].strip()
                }) %}
            {% endif %}
        {% endif %}
    {% endfor %}
    {{ return(objects) }}
{% endmacro %}
