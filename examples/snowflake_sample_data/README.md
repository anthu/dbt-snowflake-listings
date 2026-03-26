# Example: TPC-H Sample Data with Semantic View

This example demonstrates how to use `dbt_snowflake_listings` together with
[`Snowflake-Labs/dbt_semantic_view`](https://github.com/Snowflake-Labs/dbt_semantic_view)
to create an organization listing that shares TPC-H data tables **and** a
Semantic View for Cortex Analyst integration.

## What it does

1. **Staging models** copy a subset of TPC-H data from the read-only
   `SNOWFLAKE_SAMPLE_DATA` database into transient tables
2. **Semantic view** defines business-friendly dimensions, facts, and metrics
   over the staging tables using the `dbt_semantic_view` package
3. **Listing model** creates a Snowflake share containing the tables and the
   semantic view, then publishes an organization listing

The package auto-detects the object type for each `ref()` -- tables get
`GRANT SELECT ON TABLE`, the semantic view gets `GRANT REFERENCES` +
`GRANT SELECT ON SEMANTIC VIEW` plus automatic grants on underlying tables.

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` role (or a role with
  `CREATE ORGANIZATION LISTING`, `CREATE SHARE`, and `CREATE SEMANTIC VIEW`)
- `SNOWFLAKE_SAMPLE_DATA` database available (shared by default)
- dbt Core >= 1.7 with `dbt-snowflake` adapter (for local execution)
- Snowflake CLI >= 3.13.0 (for dbt Projects on Snowflake)

## Profiles

The included `profiles.yml` has two targets:

| Target | Use case | Authentication |
|--------|----------|----------------|
| `dev` (default) | dbt Projects on Snowflake | None -- Snowflake session handles auth |
| `local` | Local dbt Core execution | Environment variables (`DBT_SNOWFLAKE_ACCOUNT`, `DBT_SNOWFLAKE_USER`, `DBT_SNOWFLAKE_PASSWORD`) |

> **Developing the package locally?** Temporarily replace the git dependency in
> `packages.yml` with `- local: ../../` to test against your working copy.

## File structure

```
models/
├── staging/                          # Transient tables from SNOWFLAKE_SAMPLE_DATA
│   ├── _staging__models.yml
│   ├── stg_tpch_nation.sql           # 25 nations
│   ├── stg_tpch_region.sql           # 5 regions
│   ├── stg_tpch_customer.sql         # 5,000 customers
│   └── stg_tpch_orders.sql           # 10,000 orders
├── semantic/                         # Semantic view via dbt_semantic_view
│   ├── _semantic__models.yml
│   └── customer_analytics_sv.sql
└── listings/                         # Organization listing
    ├── _listings__models.yml         # Listing manifest (native YAML)
    └── tpch_sample_listing.sql       # share_models() with all refs
```

All object types go through a single `share_models()` call:

```sql
{{ dbt_snowflake_listings.share_models([
    ref('stg_tpch_nation'),
    ref('stg_tpch_region'),
    ref('stg_tpch_customer'),
    ref('stg_tpch_orders'),
    ref('customer_analytics_sv'),   -- semantic view, auto-detected
]) }}
```

---

## Option A: Run locally with dbt Core

### 1. Install dependencies

```bash
cd examples/snowflake_sample_data
dbt deps
```

### 2. Configure credentials

Set environment variables (the `local` target in `profiles.yml` reads these):

```bash
export DBT_SNOWFLAKE_ACCOUNT="your-account"
export DBT_SNOWFLAKE_USER="your-user"
export DBT_SNOWFLAKE_PASSWORD="your-password"
```

### 3. Run

```bash
dbt run --target local
```

### 4. Verify

```bash
dbt run-operation dbt_snowflake_listings.show_listings
dbt run-operation dbt_snowflake_listings.describe_listing \
    --args '{listing_name: TPCH_SAMPLE_LISTING}'
```

### 5. Clean up

```bash
dbt run-operation dbt_snowflake_listings.drop_listing \
    --args '{listing_name: TPCH_SAMPLE_LISTING, drop_share: TPCH_SAMPLE_SHARE}'
```

---

## Option B: Run as a dbt Project on Snowflake

dbt Projects on Snowflake lets you deploy and execute dbt projects natively
inside Snowflake -- no external compute or credentials management required.

### 1. Set up external access integration (for dbt deps)

The project depends on two remote packages. Create a network rule and
external access integration so Snowflake can download them:

```sql
CREATE OR REPLACE NETWORK RULE dbt_packages_network_rule
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION dbt_packages_access
    ALLOWED_NETWORK_RULES = (dbt_packages_network_rule)
    ENABLED = TRUE;
```

### 2. Connect Git repository

```sql
CREATE OR REPLACE SECRET git_secret
    TYPE = password
    USERNAME = '<github_user>'
    PASSWORD = '<github_pat>';

CREATE OR REPLACE API INTEGRATION git_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/<your-org>')
    ALLOWED_AUTHENTICATION_SECRETS = (git_secret)
    ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY my_db.my_schema.marketplace_listing_repo
    API_INTEGRATION = git_api_integration
    GIT_CREDENTIALS = git_secret
    ORIGIN = 'https://github.com/<your-org>/dbt-snowflake-listings.git';

ALTER GIT REPOSITORY my_db.my_schema.marketplace_listing_repo FETCH;
```

### 3. Deploy the dbt project

```sql
CREATE OR REPLACE DBT PROJECT my_db.my_schema.tpch_sample_project
    FROM '@my_db.my_schema.marketplace_listing_repo/branches/main/examples/snowflake_sample_data'
    DEFAULT_TARGET = 'dev'
    EXTERNAL_ACCESS_INTEGRATIONS = (dbt_packages_access);
```

Or with Snowflake CLI:

```bash
snow dbt deploy tpch_sample_project \
    --source ./examples/snowflake_sample_data \
    --profiles-dir ./examples/snowflake_sample_data \
    --default-target dev \
    --external-access-integration dbt_packages_access
```

### 4. Execute

```sql
EXECUTE DBT PROJECT my_db.my_schema.tpch_sample_project
    ARGS = 'run --target dev';
```

Or with Snowflake CLI:

```bash
snow dbt execute tpch_sample_project run --target dev
```

### 5. Schedule with a Snowflake task

```sql
CREATE OR ALTER TASK my_db.my_schema.refresh_tpch_listing
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '60 MINUTES'
AS
    EXECUTE DBT PROJECT my_db.my_schema.tpch_sample_project
        ARGS = 'run --target dev';

ALTER TASK my_db.my_schema.refresh_tpch_listing RESUME;
```

### 6. Monitor

```sql
DESCRIBE DBT PROJECT my_db.my_schema.tpch_sample_project;

SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    TASK_NAME => 'REFRESH_TPCH_LISTING'
))
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;
```

---

## DAG visualization

```
stg_tpch_customer ──┐
stg_tpch_orders ────┤
stg_tpch_nation ────┼── customer_analytics_sv ──┐
stg_tpch_region ────┘                           │
                    └───────────────────────────┼── tpch_sample_listing
                                                     (share + listing)
```

All staging models and the semantic view feed into the listing model via
`ref()`. dbt runs them in the correct order automatically.
