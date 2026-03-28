{% set integration_share_name = var('integration_share_name', 'DBT_MARKETPLACE_TEST_SHARE') %}
{% set integration_listing_name = var('integration_listing_name', 'TEST_ORG_LISTING') %}

{{ config(
    materialized='organization_listing',
    meta={
        'share_name': integration_share_name,
        'listing_name': integration_listing_name,
        'publish': false,
    },
) }}

{{ dbt_snowflake_listings.share_models([
    ref('stg_nation'),
    ref('stg_region'),
    ref('stg_customer'),
]) }}
