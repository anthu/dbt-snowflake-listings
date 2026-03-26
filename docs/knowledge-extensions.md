# Knowledge Extensions

## Semantic Views

Use the [`Snowflake-Labs/dbt_semantic_view`](https://github.com/Snowflake-Labs/dbt_semantic_view)
package to create semantic views as dbt models, then share them in your listing
with a single `ref()`:

```yaml
# packages.yml
packages:
  - package: Snowflake-Labs/dbt_semantic_view
    version: 1.0.3
  - git: "https://github.com/anthu/dbt-snowflake-listings.git"
    revision: v0.1.0
```

```sql
-- models/semantic/customer_sv.sql
{{ config(materialized='semantic_view') }}
TABLES(
    {{ ref('stg_customers') }} AS customers (PRIMARY KEY customer_id)
)
DIMENSIONS(customers.segment STRING)
FACTS(customers.balance NUMBER)
METRICS(total_balance AS SUM(customers.balance))
```

```sql
-- models/listings/my_listing.sql
{{ dbt_snowflake_listings.share_models([
    ref('stg_customers'),
    ref('customer_sv'),      -- auto-detected as SEMANTIC VIEW
]) }}
```

The package handles the full Snowflake sharing protocol for semantic views:
1. `GRANT REFERENCES ON SEMANTIC VIEW` (required for sharing)
2. `GRANT SELECT ON SEMANTIC VIEW` (allows consumers to query)
3. Auto-discovers underlying tables and grants `SELECT ON TABLE` for each

## Cortex Search Services (CKE)

Cortex Search Services can be shared as Cortex Knowledge Extensions. When a
Cortex Search Service is created as a dbt model (via a future materialization),
it integrates through the same `share_model(ref(...))` pattern.

For listings that include a Cortex Knowledge Extension, add
`cke_content_protection` to the manifest to control content access:

```yaml
listing_manifest:
  title: "My Knowledge Base"
  cke_content_protection:
    enable: true
    threshold: 0.2
```
