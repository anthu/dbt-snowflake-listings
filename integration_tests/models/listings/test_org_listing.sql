{{ config(
    materialized='organization_listing',
    meta={
        'share_name': 'DBT_MARKETPLACE_TEST_SHARE',
        'publish': false,
    },
) }}

{{ dbt_snowflake_listings.share_models([
    ref('stg_nation'),
    ref('stg_region'),
    ref('stg_customer'),
]) }}
