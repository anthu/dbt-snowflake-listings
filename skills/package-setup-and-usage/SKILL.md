---
name: package-setup-and-usage
description: Install, configure, and run dbt_snowflake_listings for internal marketplace listings. Use when setting up packages.yml, defining listing SQL/YAML shape, executing dbt runs, or troubleshooting lifecycle behavior.
---

# Package Setup And Usage

Use this skill for operational setup and first successful runs of `dbt_snowflake_listings`.

## Primary Goal

Get an internal listing (`organization_listing`) running with:
- correct package install
- correct SQL/YAML model shape
- predictable run lifecycle

## Setup Workflow

1. Confirm dbt/Snowflake prerequisites:
   - dbt Core `>=1.7`
   - Snowflake role has `CREATE ORGANIZATION LISTING`, `IMPORT ORGANIZATION LISTING`, `CREATE SHARE`
2. Add package in `packages.yml` using a pinned git revision.
3. Run `dbt deps`.
4. Build staging/shared models.
5. Create listing model SQL and listing schema YAML.
6. Run `dbt run`.
7. Validate listing via run-operations if needed.

## Install Pattern

```yaml
packages:
  - git: "https://github.com/anthu/dbt-snowflake-listings.git"
    revision: v0.2.3
```

Then:

```bash
dbt deps
```

## Required Listing Model Shape

```sql
{{ config(
    materialized='organization_listing',
    meta={
        'share_name': 'MY_SHARE',
        'publish': true
    }
) }}

{{ dbt_snowflake_listings.share_models([
    ref('stg_model_a'),
    ref('stg_model_b')
]) }}
```

Rules:
- keep non-standard config keys in `meta`
- list shared objects in SQL with `share_model()` or `share_models()`
- use `ref()` for DAG correctness

## Required Manifest Shape (YAML)

Put manifest in the model schema file under `config.meta.listing_manifest`.

```yaml
models:
  - name: my_listing
    config:
      meta:
        listing_manifest:
          title: "My Internal Data Product"
          description: "Purpose and contents of the listing."
          organization_targets:
            access:
              - all_internal_accounts: true
```

## Lifecycle Expectations

On `dbt run`:
- first run: create share, grant objects, create listing
- later runs: alter listing manifest and refresh grants

On `dbt run --full-refresh`:
- unpublish/drop listing, drop share, then recreate

## Fast Validation Commands

```bash
dbt run-operation dbt_snowflake_listings.show_listings
dbt run-operation dbt_snowflake_listings.describe_listing --args '{listing_name: MY_LISTING}'
```

## Common Mistakes To Catch

- missing `meta.share_name`
- missing `meta.listing_manifest`
- writing manifest in SQL instead of YAML
- forgetting `ref()` for shared objects
- using unpinned package revision in production workflows

## Escalation

If issue is content quality (wording/field completeness), switch to:
- `skills/internal-listing-manifest-authoring/SKILL.md`

If issue is readiness/review, switch to:
- `skills/listing-quality-review/SKILL.md`
