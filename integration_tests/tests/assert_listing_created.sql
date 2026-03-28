{#
    Verifies that the test organization listing was created.
    This test passes (returns 0 rows) when the listing exists.
    It fails (returns 1 row) when the listing does not exist.
#}

{% set listing_name = var('integration_listing_name', 'TEST_ORG_LISTING') %}

{% set result = run_query("SHOW LISTINGS LIKE '" ~ listing_name ~ "'") %}

{% if result | length == 0 %}
    SELECT 'Listing {{ listing_name }} was not found' AS failure_reason
{% else %}
    SELECT 'ok' AS status WHERE FALSE
{% endif %}
