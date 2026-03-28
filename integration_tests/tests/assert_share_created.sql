{#
    Verifies that the integration test share was created.
    This test passes (returns 0 rows) when the share exists.
    It fails (returns 1 row) when the share does not exist.
#}

{% set share_name = var('integration_share_name', 'DBT_MARKETPLACE_TEST_SHARE') %}

{% set result = run_query("SHOW SHARES LIKE '" ~ share_name ~ "'") %}

{% if result | length == 0 %}
    SELECT 'Share {{ share_name }} was not found' AS failure_reason
{% else %}
    SELECT 'ok' AS status WHERE FALSE
{% endif %}
