{% macro cleanup_test_listing() %}
    {#
        Tears down the test listing and share created during integration tests.
        Usage: dbt run-operation cleanup_test_listing
    #}
    {{ dbt_snowflake_listings.drop_listing(
        listing_name='TEST_ORG_LISTING',
        drop_share='DBT_MARKETPLACE_TEST_SHARE'
    ) }}
{% endmacro %}
