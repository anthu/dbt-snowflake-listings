{# Native dbt batching + listing DDL: see ../../../README.md and repo docs/snowflake-projects.md #}}
{{ config(
    materialized='organization_listing',
    meta={
        'share_name': 'TPCH_SAMPLE_SHARE',
        'publish': true,
    },
) }}

{{ dbt_snowflake_listings.share_models([
    ref('stg_tpch_nation'),
    ref('stg_tpch_region'),
    ref('stg_tpch_customer'),
    ref('stg_tpch_orders'),
]) }}
