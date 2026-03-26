# Run-Operation Macros

For ad-hoc operations outside the `dbt run` lifecycle:

## drop_listing

Drop a listing and optionally its share:

```bash
dbt run-operation dbt_snowflake_listings.drop_listing \
    --args '{listing_name: MY_LISTING, drop_share: MY_SHARE}'
```

## show_listings

Show all organization listings:

```bash
dbt run-operation dbt_snowflake_listings.show_listings
```

Show listings matching a pattern:

```bash
dbt run-operation dbt_snowflake_listings.show_listings \
    --args '{like: "TPCH_%"}'
```

## describe_listing

Describe a specific listing:

```bash
dbt run-operation dbt_snowflake_listings.describe_listing \
    --args '{listing_name: MY_LISTING}'
```

## grant_listing_privileges

Grant organization listing privileges to a role:

```bash
dbt run-operation dbt_snowflake_listings.grant_listing_privileges \
    --args '{role: DATA_SHARING_ROLE}'
```

Grant external (marketplace) listing privileges to a role:

```bash
dbt run-operation dbt_snowflake_listings.grant_listing_privileges \
    --args '{role: DATA_SHARING_ROLE, listing_type: external}'
```
