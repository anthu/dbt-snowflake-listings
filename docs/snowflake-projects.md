# dbt Projects on Snowflake

This package works with [dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake),
allowing you to deploy and run listings natively inside Snowflake -- no
external compute or credentials management required.

## Deploy from a Git Repository

```sql
CREATE OR REPLACE DBT PROJECT my_db.my_schema.marketplace_project
    FROM '@my_db.my_schema.my_git_repo/branches/main'
    DEFAULT_TARGET = 'dev'
    EXTERNAL_ACCESS_INTEGRATIONS = (dbt_packages_access);
```

## Execute

```sql
EXECUTE DBT PROJECT my_db.my_schema.marketplace_project
    ARGS = 'run --target dev';
```

## Schedule

```sql
CREATE OR ALTER TASK my_db.my_schema.refresh_listings
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '60 MINUTES'
AS
    EXECUTE DBT PROJECT my_db.my_schema.marketplace_project
        ARGS = 'run --target dev';
```

## Using Snowflake CLI

```bash
snow dbt deploy marketplace_project --source . --default-target dev
snow dbt execute marketplace_project run --target dev
```

## Dependencies

dbt Projects on Snowflake can automatically run `dbt deps` during compilation
when you provide an `EXTERNAL_ACCESS_INTEGRATIONS` parameter. See the
[Snowflake documentation on dbt dependencies](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-dependencies)
for details on network rules and external access integrations.

> **Note:** Snowflake does not support parent-directory `local:` references
> (e.g. `local: ../../`). Packages must be referenced via git URL or copied
> into the project root. See the
> [example project](../examples/snowflake_sample_data/) for a working setup.

## Complete Example

See [`examples/snowflake_sample_data/`](../examples/snowflake_sample_data/) for a
complete walkthrough including Git repository setup, external access
integration configuration, scheduling, and monitoring.
