{% macro create_test_db(database_name=none) %}
    {#
        Creates the integration test database if it does not already exist.
        Usage: dbt run-operation create_test_db
    #}
    {% set target_database = database_name if database_name else env_var('DBT_SNOWFLAKE_DATABASE', 'DBT_MARKETPLACE_TEST') %}

    {{ log("Ensuring integration test database exists: " ~ target_database, info=True) }}
    {% call statement('create_test_db', fetch_result=false) %}
        CREATE DATABASE IF NOT EXISTS {{ target_database }}
    {% endcall %}
{% endmacro %}

{% macro cleanup_test_listing(listing_name=none, drop_share=none) %}
    {#
        Tears down the test listing and share created during integration tests.
        Usage: dbt run-operation cleanup_test_listing
    #}
    {% set resolved_listing_name = listing_name if listing_name else var('integration_listing_name', 'TEST_ORG_LISTING') %}
    {% set resolved_share_name = drop_share if drop_share else var('integration_share_name', 'DBT_MARKETPLACE_TEST_SHARE') %}

    {{ dbt_snowflake_listings.drop_listing(
        listing_name=resolved_listing_name,
        drop_share=resolved_share_name
    ) }}
{% endmacro %}
