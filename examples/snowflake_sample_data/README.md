# Example: TPC-H sample data organization listing

This example uses `dbt_snowflake_listings` to build an **organization listing**
that shares TPC-H staging tables from `SNOWFLAKE_SAMPLE_DATA` via a Snowflake
share. The dbt project lives under **`sources/dbt_example/`**; the repo root
here (`manifest.yaml`, `setup.sql`) aligns with a **DCM Projects** layout for
[`DEFINE DBT PROJECT`](https://docs.snowflake.com/en/LIMITEDACCESS/dcm-projects/dcm-projects-early-access).

## Layout

```text
examples/snowflake_sample_data/
  manifest.yaml          # DCM-oriented notes + metadata (see Snowflake DCM docs)
  setup.sql              # Database + network rule + EAI (run once per account)
  README.md
  sources/
    dbt_example/         # dbt project root (models, packages.yml, profiles)
      dbt_project.yml
      packages.yml
      profiles.yml
      macros/
      models/
```

## What it does

1. **Staging models** copy a subset of TPC-H data into **transient** tables.
2. **Listing model** creates a share and an **organization listing** with a YAML manifest.

## Native dbt on Snowflake: dollar-quoted listing DDL

If you maintain **other** dbt packages or custom materializations that emit
`CREATE … AS $$ … $$` inside a single `statement()`, **dbt Projects on Snowflake**
can truncate that SQL and return `syntax error … unexpected '<EOF>'`, while
**dbt Core** + open-source `dbt-snowflake` often succeed. This package works
around that by wrapping listing DDL in **`EXECUTE IMMEDIATE $$ … $$`**.

**Pin a released package version** (see `sources/dbt_example/packages.yml`) that
includes that workaround — do not rely on floating `main` for production deploys.
Details: [dbt Projects on Snowflake](../../docs/snowflake-projects.md).

## Prerequisites

- Role with `CREATE ORGANIZATION LISTING`, `CREATE SHARE`, and object DDL in `MY_LISTING_DB`
- `SNOWFLAKE_SAMPLE_DATA` available
- dbt Core >= 1.7 + `dbt-snowflake` for local runs
- Snowflake CLI for native dbt deploy

## Profiles

See `sources/dbt_example/profiles.yml` (and `.example`):

| Target | Use case | Authentication |
|--------|----------|----------------|
| `dev` (default) | dbt Projects on Snowflake | Session auth |
| `local` | Local dbt Core | `DBT_SNOWFLAKE_*` env vars |

Local dev against a **git** checkout of this repo: in `packages.yml` you may use
`- local: ../../../` temporarily (three levels up from `sources/dbt_example/` to
the package root). Native Snowflake **cannot** use parent `local:` paths — use a
git `revision` there.

---

## Option A: Run locally with dbt Core

```bash
cd examples/snowflake_sample_data/sources/dbt_example
dbt deps
export DBT_SNOWFLAKE_ACCOUNT="..." DBT_SNOWFLAKE_USER="..." DBT_SNOWFLAKE_PASSWORD="..."
dbt run --target local
```

Verify / clean up (from the same directory):

```bash
dbt run-operation dbt_snowflake_listings.show_listings
dbt run-operation dbt_snowflake_listings.describe_listing \
  --args '{listing_name: TPCH_SAMPLE_LISTING}'
dbt run-operation dbt_snowflake_listings.drop_listing \
  --args '{listing_name: TPCH_SAMPLE_LISTING, drop_share: TPCH_SAMPLE_SHARE}'
```

---

## Option B: dbt Projects on Snowflake (CLI)

### 1. Account bootstrap

Run [`setup.sql`](setup.sql) in Worksheets or `snow sql` (edit integration name /
`GRANT` role to match your account). It creates `MY_LISTING_DB`, egress network
rule `DBT_PACKAGES_NETWORK_RULE`, and integration `DBT_PACKAGES_ACCESS`.

### 2. Git repository (if deploying from Git)

Same as before: API integration + Git repo pointing at this repository. The path
**inside the repo** to the dbt project is:

`examples/snowflake_sample_data/sources/dbt_example`

### 3. Deploy

From the **git repo root** on your machine:

```bash
snow dbt deploy TPCH_SAMPLE_DBT_EXAMPLE \
  --connection <your_connection> \
  --source examples/snowflake_sample_data/sources/dbt_example \
  --profiles-dir examples/snowflake_sample_data/sources/dbt_example \
  --default-target dev \
  --external-access-integration DBT_PACKAGES_ACCESS
```

Or SQL:

```sql
CREATE OR REPLACE DBT PROJECT my_db.my_schema.tpch_sample_project
    FROM '@my_db.my_schema.my_repo/branches/main/examples/snowflake_sample_data/sources/dbt_example'
    DEFAULT_TARGET = 'dev'
    EXTERNAL_ACCESS_INTEGRATIONS = (DBT_PACKAGES_ACCESS);
```

### 4. Execute

```bash
snow dbt execute --connection <your_connection> TPCH_SAMPLE_DBT_EXAMPLE run --target dev
```

(`--connection` must appear **before** the project name.)

---

## Option C: DCM Projects + DEFINE DBT PROJECT

See [DCM Projects overview](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-overview)
and [early-access dbt](https://docs.snowflake.com/en/LIMITEDACCESS/dcm-projects/dcm-projects-early-access).

- DCM project directory: **`examples/snowflake_sample_data/`** (this folder).
- dbt subtree: **`sources/dbt_example/`** — use `from 'sources/dbt_example'` in
  `DEFINE DBT PROJECT` (syntax varies by DCM release; see `manifest.yaml` comments).
- Run **`setup.sql`** once (or attach equivalent DDL as a DCM **pre-hook**).
- Reference integration name in `EXTERNAL_ACCESS_INTEGRATIONS` on the DBT PROJECT
  definition (match `setup.sql` or your naming).

---

## DAG

```
stg_tpch_nation  ─┐
stg_tpch_region  ─┤
stg_tpch_customer┼── tpch_sample_listing (share + listing)
stg_tpch_orders  ─┘
```
