# AGENTS Guide

This file defines how an agent should work with `dbt_snowflake_listings`.
Default focus is internal marketplace (`organization_listing`).

## Scope and Priority

- Treat `organization_listing` as the primary production path.
- Treat `external_listing` as secondary and explicitly blueprint-level unless the user asks for it.
- Keep changes consistent with the package's two-file authoring model:
  - listing model `.sql` for `share_model()` / `share_models()` dependencies
  - schema `.yml` for `config.meta.listing_manifest`

## When To Use Project Skills

Use skills under `./skills/` as follows:

- `skills/package-setup-and-usage/SKILL.md`
  - when user asks how to install, configure, run, troubleshoot, or upgrade this package
- `skills/internal-listing-manifest-authoring/SKILL.md`
  - when user asks to create or improve internal listing manifest content
  - includes guidance for wording, length, structure, and ownership/contact fields
- `skills/listing-quality-review/SKILL.md`
  - when user asks for review, quality audit, or readiness checks for listing SQL/YAML

If request spans multiple concerns, apply skills in this order:
1. setup and usage
2. manifest authoring
3. quality review

## Non-Negotiable Package Conventions

- Use namespaced macros in examples and changes:
  - `dbt_snowflake_listings.share_model(...)`
  - `dbt_snowflake_listings.share_models(...)`
  - `dbt_snowflake_listings.listing_ref(...)`
- Keep custom listing config under `meta` (dbt 1.11+ behavior).
- Keep manifests in model YAML (`config.meta.listing_manifest`), not in SQL strings.
- Prefer fully qualified clarity in manifest usage examples.
- Preserve idempotent lifecycle expectations:
  - first run: create share + grants + listing
  - rerun: alter listing + re-grant objects
  - full refresh: unpublish/drop/recreate

## Internal Listing Workflow

Follow this workflow unless user requests a different shape:

1. Build staging/shared models.
2. Create listing model with `materialized='organization_listing'` and `meta.share_name`.
3. Register shared objects with `share_model()` / `share_models()` and `ref()`.
4. Author `listing_manifest` in YAML with required fields.
5. Run `dbt run`; validate with `show_listings` / `describe_listing` macros as needed.
6. For iterative changes, update YAML and rerun; use `--full-refresh` only when reset is required.

## Manifest Guardrails (Internal Marketplace)

For `organization_listing`, ensure at minimum:

- `title` present and concise (<= 110 chars)
- `description` present, clear audience/value, markdown-safe
- `organization_targets` includes access/discovery intent
- optional but recommended:
  - `locations.access_regions`
  - `auto_fulfillment` only when cross-region requirements apply
  - `usage_examples` with runnable, realistic SQL
  - `support_contact` / `approver_contact` when governance requires named ownership

Reference: [Snowflake listing manifest reference](https://docs.snowflake.com/en/progaccess/listing-manifest-reference)

## Writing Quality Standards

- Write titles/subtitles in product language, not table names alone.
- Keep descriptions outcome-oriented (what consumers can do).
- Avoid hype and unbounded claims ("real-time", "complete", "all data") unless proven.
- Use consistent domain terms across SQL model names and manifest prose.
- Usage examples should be practical, bounded, and easy to adapt.

## Agent Behavior Expectations

- Fix root causes, not symptoms (for docs/code drift, update the source of truth and references).
- Prefer minimal, targeted edits; avoid broad refactors unless asked.
- Do not add tests or documentation unless requested by user policy in session context.
- If a request conflicts with package constraints, explain the conflict and propose the safest path.
