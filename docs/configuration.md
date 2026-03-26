# Configuration Reference

All custom config lives under `meta` (required by dbt 1.11+ for non-standard keys).
Config can be split across the `.sql` config block and the `.yml` schema file
(dbt merges `meta` from both).

## Organization Listing Config

| Config (under `meta`) | Type | Required | Default | Description |
|------------------------|------|----------|---------|-------------|
| `share_name` | string | yes | -- | Name of the Snowflake share to create |
| `listing_manifest` | dict | yes | -- | The YAML manifest (best in `.yml` file) |
| `listing_name` | string | no | `model.name \| upper` | Override the listing identifier |
| `publish` | bool | no | `true` | Publish listing after create/alter |
| `secure_objects_only` | bool | no | `false` | Share `SECURE_OBJECTS_ONLY` flag |

For external listing config, see [External Listing (Blueprint)](#external-listing-blueprint).

## Sharing Models

Models to share are declared in the `.sql` model body, not in config:

```sql
{# Single model #}
{{ dbt_snowflake_listings.share_model(ref('my_model')) }}

{# Multiple models #}
{{ dbt_snowflake_listings.share_models([
    ref('my_table'),
    ref('my_view'),
    ref('my_semantic_view'),
]) }}
```

The package auto-detects each object's type at runtime by cascading through
Snowflake metadata:

| Detected type | Grant issued |
|---------------|-------------|
| TABLE | `GRANT SELECT ON TABLE` |
| VIEW | `GRANT SELECT ON VIEW` |
| SEMANTIC VIEW | `GRANT REFERENCES ON SEMANTIC VIEW` + `GRANT SELECT ON SEMANTIC VIEW` + `GRANT SELECT ON TABLE` for each underlying table |
| CORTEX SEARCH SERVICE | `GRANT USAGE ON CORTEX SEARCH SERVICE` |

Underlying tables referenced by a semantic view are discovered automatically
via `DESCRIBE SEMANTIC VIEW` and granted to the share -- you don't need to
list them separately (though you can for clarity or if you want consumers to
access the raw tables directly).

## Listing Manifest

The `listing_manifest` config is a dict that maps directly to the
[Snowflake Organization Listing Manifest](https://docs.snowflake.com/en/user-guide/collaboration/listings/organizational/org-listing-manifest-reference).

Required fields:
- `title` (string, max 110 chars)
- `organization_targets` with `access` and/or `discovery`

Common optional fields:
- `description` (string, max 7500 chars, supports Markdown)
- `organization_profile` (default: `"INTERNAL"`)
- `locations.access_regions`
- `auto_fulfillment` (required for cross-region sharing)
- `support_contact` / `approver_contact`
- `usage_examples`
- `listing_terms`
- `data_dictionary`
- `data_attributes`
- `cke_content_protection` (for Cortex Knowledge Extension listings)

---

## External Listing (Blueprint)

> **This materialization is a blueprint.** It has been implemented based on the
> [Snowflake documentation](https://docs.snowflake.com/en/sql-reference/sql/create-listing)
> but has **not been tested against a real Snowflake Marketplace account**. Treat
> it as a starting point -- you may need to adjust SQL syntax, manifest fields,
> or the review/publish workflow based on actual Snowflake behavior.

The `external_listing` materialization follows the same two-file pattern as
`organization_listing` but targets the public Snowflake Marketplace via
`CREATE EXTERNAL LISTING`.

### Listing model (`.sql`)

```sql
-- models/listings/public_data_listing.sql
{{ config(
    materialized='external_listing',
    meta={
        'share_name': 'PUBLIC_DATA_SHARE',
        'publish': false,
        'review': false,
    },
) }}

{{ dbt_snowflake_listings.share_models([
    ref('stg_customers'),
    ref('stg_orders'),
]) }}
```

### Listing manifest (`.yml`)

```yaml
# models/listings/_listings__models.yml
models:
  - name: public_data_listing
    description: "Public marketplace listing for customer analytics"
    config:
      meta:
        listing_manifest:
          title: "Customer Analytics Data"
          subtitle: "Anonymized customer and order data"
          description: |
            Customer and order data for analytics use cases.
          profile: "My Provider Profile"
          listing_terms:
            type: "STANDARD"
          targets:
            regions: ["PUBLIC.AWS_US_EAST_1"]
          auto_fulfillment:
            refresh_type: "SUB_DATABASE"
            refresh_schedule: "60 MINUTE"
          resources:
            documentation: "https://example.com/docs"
          categories:
            - BUSINESS
          data_dictionary:
            featured:
              database: "ANALYTICS_DB"
              objects:
                - name: "CUSTOMERS"
                  schema: "PUBLIC"
                  domain: "TABLE"
          data_preview:
            has_pii: false
          data_attributes:
            refresh_rate: DAILY
            geography:
              granularity:
                - COUNTRY
              geo_option: GLOBAL
              time:
                granularity: DAILY
                time_range:
                  time_frame: LAST
                  unit: YEARS
                  value: 1
          usage_examples:
            - title: "Customer order summary"
              description: "Aggregate orders by customer"
              query: "SELECT customer_id, COUNT(*) FROM orders GROUP BY 1"
```

### External Listing Config

| Config (under `meta`) | Type | Required | Default | Description |
|------------------------|------|----------|---------|-------------|
| `share_name` | string | yes | -- | Name of the Snowflake share to create |
| `listing_manifest` | dict | yes | -- | The YAML manifest (in `.yml` file) |
| `listing_name` | string | no | `model.name \| upper` | Override the listing identifier |
| `publish` | bool | no | `true` | Publish listing after create/alter |
| `review` | bool | no | `true` | Submit listing for Marketplace Ops review |
| `comment` | string | no | -- | Comment attached to the listing |
| `secure_objects_only` | bool | no | `false` | Share `SECURE_OBJECTS_ONLY` flag |

### Required Manifest Fields

External listings have stricter manifest requirements than organization listings:

| Field | Required | Notes |
|-------|----------|-------|
| `title` | Always | Max 110 characters |
| `listing_terms` | Always | `type`: `STANDARD`, `OFFLINE`, or `CUSTOM` |
| `targets` (V1) or `external_targets` (V2) | Always | Target accounts, regions, or organizations |
| `subtitle` | Marketplace | Max 110 characters |
| `profile` | Marketplace | Approved provider profile name |
| `resources` | Marketplace | `documentation` URL (required), `media` YouTube URL (optional) |
| `data_dictionary` | Public | Featured database and objects |
| `data_preview` | Public | PII declaration |
| `categories` | Marketplace | Single category from the Snowflake-defined list |
| `data_attributes` | Marketplace | Refresh rate, geography, and time coverage |

For the full manifest specification, see the
[Snowflake Listing Manifest Reference](https://docs.snowflake.com/en/progaccess/listing-manifest-reference).

### PUBLISH and REVIEW Interaction

External listings require Marketplace Ops review before they can be published
publicly. The `publish` and `review` config keys map to the `PUBLISH` and
`REVIEW` parameters on `CREATE EXTERNAL LISTING`:

| `publish` | `review` | Behavior |
|-----------|----------|----------|
| `true` | `true` | Request review, then publish automatically after approval |
| `true` | `false` | **Error** -- cannot publish without review |
| `false` | `true` | Request review without auto-publishing |
| `false` | `false` | Save as draft (no review, no publish) |

### External Listing Privileges

External listings require `CREATE LISTING` (not `CREATE ORGANIZATION LISTING`):

```bash
dbt run-operation dbt_snowflake_listings.grant_listing_privileges \
    --args '{role: MARKETPLACE_ROLE, listing_type: external}'
```
