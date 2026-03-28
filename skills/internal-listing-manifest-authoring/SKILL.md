---
name: internal-listing-manifest-authoring
description: Author and improve high-quality internal marketplace listing manifests for dbt_snowflake_listings. Use when writing listing_manifest YAML, refining title/description/examples, defining ownership/contact fields, and checking Snowflake field requirements.
---

# Internal Listing Manifest Authoring

Use this skill to write or improve `organization_listing` manifest content in YAML.

Reference spec:
- [Snowflake listing manifest reference](https://docs.snowflake.com/en/progaccess/listing-manifest-reference)

## Output Target

Write manifest content under:

```yaml
models:
  - name: <listing_model_name>
    config:
      meta:
        listing_manifest:
          ...
```

Do not move manifest data into SQL.

## Internal Listing Minimum

For internal marketplace usage, require:
- `title`
- `description`
- `organization_targets` (access/discovery intent)

Strongly recommended:
- `organization_profile: "INTERNAL"`
- `locations.access_regions` (`ALL` or explicit region set)
- `usage_examples`
- ownership/support fields when governance requires named accountability

## Writing Standards

### Title

- Max length: 110 characters
- Prefer product/value language over physical object names
- Pattern: `<Domain>: <Primary value>`
- Avoid:
  - ambiguous names ("Data Share", "Reporting Data")
  - team-internal shorthand

### Description

- Max length: 7500 characters, markdown supported
- Structure:
  1. what this listing contains
  2. who it is for
  3. what decisions/workflows it supports
  4. key boundaries (refresh behavior, scope caveats)
- Keep claims verifiable; avoid hype terms unless measurable

### Ownership and Contacts

When available, include clear ownership and escalation paths using manifest contact fields (for example support/approver contacts in your organization's policy).

Guidelines:
- use role inboxes over personal emails where possible
- include business owner and technical support if process requires both
- ensure contact naming is consistent with internal governance language

### Usage Examples

- Add 1-3 realistic examples with:
  - clear title
  - short description
  - runnable SQL query
- Keep SQL bounded (`LIMIT`, narrow joins, concrete columns)
- Prefer examples aligned to common consumer questions

## Authoring Template

```yaml
listing_manifest:
  title: "Finance: Monthly Revenue and Customer Retention"
  description: |
    Curated finance-ready datasets for monthly revenue analysis and retention monitoring.

    Intended consumers: Finance analytics and executive reporting teams.
    Includes standardized customer, order, and region dimensions with stable keys.
    Refresh behavior: updated every 10 minutes via SUB_DATABASE auto-fulfillment.
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
    - title: "Top customers by monthly spend"
      description: "Ranks customers by spend using the shared orders dataset"
      query: >
        SELECT customer_id, SUM(total_price) AS spend
        FROM ORDERS
        GROUP BY 1
        ORDER BY spend DESC
        LIMIT 50
```

## Style Checks Before Finalizing

- Title is specific and under 110 chars.
- Description is clear, audience-aware, and not redundant.
- Targets and regions reflect intended discoverability/access.
- Auto-fulfillment only included when required by cross-region behavior.
- Examples are useful, accurate, and syntactically coherent.
- Ownership/contact wording matches internal policy language.

## Handoff

If user asks for readiness/compliance review after authoring, switch to:
- `skills/listing-quality-review/SKILL.md`
