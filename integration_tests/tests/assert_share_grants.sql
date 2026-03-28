{#
    Verifies required table SELECT grants exist on the integration test share.
    This test passes (returns 0 rows) when all expected grants are present.
    It fails (returns 1 row) when one or more grants are missing.
#}

{% set share_name = var('integration_share_name', 'DBT_MARKETPLACE_TEST_SHARE') %}
{% set expected_tables = ['STG_NATION', 'STG_REGION', 'STG_CUSTOMER'] %}

{% set grants_result = run_query("SHOW GRANTS TO SHARE " ~ share_name) %}

{% if grants_result | length == 0 %}
    SELECT 'No grants found for share {{ share_name }}' AS failure_reason
{% else %}
    {% set grant_names = grants_result.columns['name'].values() %}
    {% set grant_targets = grants_result.columns['granted_on'].values() %}
    {% set grant_privileges = grants_result.columns['privilege'].values() %}
    {% set missing_tables = [] %}

    {% for expected_table in expected_tables %}
        {% set ns = namespace(found=false) %}
        {% for idx in range(grant_names | length) %}
            {% if grant_names[idx] | upper == expected_table
                  and grant_targets[idx] | upper == 'TABLE'
                  and grant_privileges[idx] | upper == 'SELECT' %}
                {% set ns.found = true %}
            {% endif %}
        {% endfor %}
        {% if not ns.found %}
            {% do missing_tables.append(expected_table) %}
        {% endif %}
    {% endfor %}

    {% if missing_tables | length > 0 %}
        SELECT 'Missing SELECT grants on TABLE for: {{ missing_tables | join(", ") }}' AS failure_reason
    {% else %}
        SELECT 'ok' AS status WHERE FALSE
    {% endif %}
{% endif %}
