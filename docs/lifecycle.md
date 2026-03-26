# Lifecycle Behavior

Both `organization_listing` and `external_listing` follow the same lifecycle:

| Scenario | What happens |
|----------|-------------|
| First `dbt run` | CREATE SHARE, GRANT objects, CREATE listing (`ORGANIZATION` or `EXTERNAL`) |
| Subsequent `dbt run` | ALTER LISTING with updated manifest, re-grant objects to share |
| `dbt run --full-refresh` | UNPUBLISH + DROP LISTING + DROP SHARE, then recreate everything |
| Manifest change in `.yml` | ALTER LISTING picks up new manifest on next `dbt run` |
| New `ref()` added to `.sql` | Object granted to share on next `dbt run` |
