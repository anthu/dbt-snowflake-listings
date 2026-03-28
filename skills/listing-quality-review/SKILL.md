---
name: listing-quality-review
description: Review internal listing SQL and manifest YAML for production readiness in dbt_snowflake_listings. Use when auditing quality, validating required fields, checking wording/examples/ownership, and producing pass-fail remediation guidance.
---

# Listing Quality Review

Use this skill to review `organization_listing` implementations before release.

## Inputs To Review

- listing SQL model (`materialized='organization_listing'`)
- schema YAML with `config.meta.listing_manifest`
- any run/test evidence if provided

## Review Checklist

### A) Package Shape And Wiring

- SQL model uses `materialized='organization_listing'`.
- `meta.share_name` is present.
- shared objects declared with `dbt_snowflake_listings.share_model()` or `share_models()`.
- shared objects use `ref()` (no hardcoded relation strings for DAG dependencies).

### B) Manifest Requirements

- `title` present and concise.
- `description` present and meaningful.
- `organization_targets` present with intended access/discovery behavior.
- manifest lives in YAML (`config.meta.listing_manifest`), not embedded in SQL.

### C) Internal Marketplace Quality

- `organization_profile` is set intentionally (typically `INTERNAL`).
- `locations.access_regions` is explicit (`ALL` or constrained set).
- `auto_fulfillment` is present only when cross-region behavior requires it.
- `usage_examples` exist and are useful for consumers.

### D) Content Quality

- title communicates data product intent, not only table names.
- description identifies:
  - intended users
  - key use cases
  - boundaries/limitations
- language is precise and non-hype.
- SQL examples are coherent, bounded, and practical.

### E) Ownership And Governance

- support/approver/owner contact fields are present when process requires them.
- ownership wording is clear (who owns, who supports, escalation path).

## Severity Model

- `Critical`: prevents listing from working or violates required manifest rules.
- `High`: likely to cause consumer confusion, governance gaps, or operational errors.
- `Medium`: quality issues that reduce discoverability/usability.
- `Low`: polish and consistency improvements.

## Output Format

Return findings first, sorted by severity.

Use this template:

```markdown
## Findings
- Critical: <issue> (`path`)
- High: <issue> (`path`)

## Pass/Fail
- Result: PASS | FAIL
- Reason: <single sentence>

## Remediation
1. <highest-priority fix>
2. <next fix>
3. <next fix>
```

Rules:
- Include file path for each finding.
- Keep findings actionable and specific.
- Recommend root-cause fixes before symptom fixes.

## Fast Fail Conditions

Immediately fail if any are true:
- missing `meta.share_name`
- missing `listing_manifest`
- missing required internal listing fields (`title`, `description`, `organization_targets`)
- listing SQL does not declare share objects

## Reference

- [Snowflake listing manifest reference](https://docs.snowflake.com/en/progaccess/listing-manifest-reference)
