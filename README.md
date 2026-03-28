# dbt_snowflake_listings

A dbt package for declaratively managing Snowflake **Organization Listings**
(Internal Marketplace) and **External Listings** (Public Snowflake Marketplace)
using custom materializations.

Define your listings as dbt models. Run `dbt run`. Shares, grants, and listings
are created and managed automatically -- fully integrated into the dbt DAG.

## Features

- **Custom `organization_listing` materialization** -- internal listings as code, managed by `dbt run`
- **Custom `external_listing` materialization (blueprint)** -- public Snowflake Marketplace listings as code
- **Two-file pattern** -- `.sql` for DAG dependencies via `ref()`, `.yml` for the listing manifest as native YAML
- **Auto-detection of object types** -- TABLE, VIEW, Semantic View, and Cortex Search Service resolved at runtime
- **Knowledge Extension support** -- share Semantic Views (with auto-grant on underlying tables) and Cortex Search Services
- **Full lifecycle management** -- create, alter, publish, unpublish, drop
- **`--full-refresh` support** -- drops and recreates listings from scratch
- **Idempotent** -- re-running `dbt run` updates existing listings via ALTER
- **dbt Projects on Snowflake** -- deploy and run natively in Snowflake
- **`listing_ref()` macro** -- build [ULL-based](https://docs.snowflake.com/en/user-guide/collaboration/listings/organizational/org-listing-query) SQL references to objects in an organization listing

## Prerequisites

- **dbt Core** >= 1.7 with `dbt-snowflake` adapter
- **Snowflake role** with listing privileges and `CREATE SHARE`
  (typically `ACCOUNTADMIN`, or use `grant_listing_privileges` to set up a custom role):
  - For organization listings: `CREATE ORGANIZATION LISTING` + `IMPORT ORGANIZATION LISTING`
  - For external listings: `CREATE LISTING`
- **Organization listings** must be enabled for your Snowflake account (for `organization_listing`)
- **Provider profile** approved on Snowflake Marketplace (for `external_listing`)
- **For Semantic Views**: `CREATE SEMANTIC VIEW` privilege and the
  `Snowflake-Labs/dbt_semantic_view` package

## Installation

Add to your `packages.yml`:

```yaml
packages:
  - git: "https://github.com/anthu/dbt-snowflake-listings.git"
    revision: v0.2.2
```

Then run:

```bash
dbt deps
```

## Quick Start

### 1. Create staging models for the data you want to share

Standard dbt models -- nothing special here:

```sql
-- models/staging/stg_customers.sql
SELECT * FROM RAW.CUSTOMERS
```

### 2. Create the listing model (`.sql` file)

Use `share_model()` or `share_models()` to declare what goes into the share.
Each `ref()` registers a DAG dependency so staging models run first.
Object types are auto-detected -- tables, views, and semantic views all go
through the same function.

```sql
-- models/listings/customer_data_listing.sql
{{ config(
    materialized='organization_listing',
    meta={
        'share_name': 'CUSTOMER_DATA_SHARE',
        'publish': true,
    },
) }}

{{ dbt_snowflake_listings.share_models([
    ref('stg_customers'),
    ref('stg_orders'),
    ref('stg_products'),
    ref('customer_semantic_view'),
]) }}
```

### 3. Define the listing manifest (`.yml` file)

The manifest lives in your model's YAML schema file as native YAML under
`config.meta.listing_manifest` (see the
[Snowflake Manifest Reference](https://docs.snowflake.com/en/user-guide/collaboration/listings/organizational/org-listing-manifest-reference)):

```yaml
# models/listings/_listings__models.yml
models:
  - name: customer_data_listing
    description: "Customer data listing for internal teams"
    config:
      meta:
        listing_manifest:
          title: "Customer Analytics Data"
          description: |
            Customer, order, and product data for internal analytics.
          organization_profile: "INTERNAL"
          organization_targets:
            access:
              - all_internal_accounts: true
          locations:
            access_regions:
              - name: "ALL"
          auto_fulfillment:
            refresh_type: "SUB_DATABASE"
            refresh_schedule: "10 MINUTE"
          usage_examples:
            - title: "Customer order summary"
              query: "SELECT customer_id, COUNT(*) FROM orders GROUP BY 1"
```

### 4. Run dbt

```bash
dbt run
```

dbt will:
1. Create the staging tables (normal table materialization)
2. Create the share and grant objects to it (auto-detecting types)
3. Create the organization listing with the YAML manifest
4. Publish the listing to the Internal Marketplace

## Documentation

| Topic | Description |
|-------|-------------|
| [Configuration Reference](docs/configuration.md) | Organization & external listing config, sharing models, `listing_ref` / ULL, manifest fields |
| [Knowledge Extensions](docs/knowledge-extensions.md) | Semantic Views and Cortex Search Services |
| [Lifecycle Behavior](docs/lifecycle.md) | What happens on each `dbt run`, `--full-refresh`, manifest changes |
| [Run-Operation Macros](docs/macros.md) | Ad-hoc operations: drop, show, describe, grant |
| [dbt Projects on Snowflake](docs/snowflake-projects.md) | Deploy, execute, and schedule listings natively in Snowflake |
| [Native dbt listing DDL repro](docs/snowflake-native-dbt-listing-repro.md) | Text for Snowflake support / product when hosted dbt truncates listing SQL |

## Example

See [`examples/snowflake_sample_data/`](examples/snowflake_sample_data/) for a
complete working example that shares TPC-H staging tables via an organization
listing. The dbt project is under `sources/dbt_example/`; `setup.sql` and
`manifest.yaml` support native dbt deploy and DCM Projects layouts.

## Development

### Running integration tests

```bash
cd integration_tests
cp profiles.yml.example profiles.yml   # then edit with your credentials
cp .env.example .env                    # then edit with your credentials
source .env
./scripts/run_tests.sh
```

## License

Apache 2.0 -- see [LICENSE](LICENSE).
