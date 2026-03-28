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
snow dbt deploy marketplace_project --source path/to/dbt_project_root --profiles-dir path/to/dbt_project_root --default-target dev --external-access-integration <eai_name>
snow dbt execute --connection <connection_name> marketplace_project run --target dev
```

Place `--connection` **before** the DBT PROJECT name on `snow dbt execute`. The
[example](../examples/snowflake_sample_data/) dbt root is
`examples/snowflake_sample_data/sources/dbt_example/`; run
[`examples/snowflake_sample_data/setup.sql`](../examples/snowflake_sample_data/setup.sql)
first for database + EAI.

## Dependencies

dbt Projects on Snowflake can automatically run `dbt deps` during compilation
when you provide an `EXTERNAL_ACCESS_INTEGRATIONS` parameter. See the
[Snowflake documentation on dbt dependencies](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-dependencies)
for details on network rules and external access integrations.

> **Note:** Snowflake does not support parent-directory `local:` references
> (e.g. `local: ../../`). Packages must be referenced via git URL or copied
> into the project root. See the
> [example project](../examples/snowflake_sample_data/) for a working setup.

## `generate_schema_name` and `deps_compile`

When Snowflake compiles a dbt project (`deps_compile` phase), the Jinja context
differs from a local `dbt compile`. In particular, the bare `{{ default_schema }}`
variable that dbt normally injects is **not available** during `deps_compile`,
which causes introspection queries like `SHOW OBJECTS IN <db>.<schema>` to emit
an empty schema name and fail with a syntax error.

If your project overrides `generate_schema_name`, make sure it explicitly
derives `default_schema` from `target.schema`:

```jinja
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

This matches dbt's own internal definition and works correctly in both local and
Snowflake-hosted execution contexts. The
[example project](../examples/snowflake_sample_data/sources/dbt_example/) ships this macro by default.

## Complete Example

See [`examples/snowflake_sample_data/`](../examples/snowflake_sample_data/) for a
complete walkthrough including Git repository setup, external access
integration configuration, scheduling, and monitoring.

## How other packages send listing-like DDL (research notes)

These notes come from reading current **Snowflake-Labs/dbt_semantic_view** and
**dbt-labs/dbt-adapters** (dbt-snowflake) source; **dbt Projects on Snowflake**
may not use identical splitting code, but local dbt + `dbt-snowflake` does.

### `dbt_semantic_view`: one `statement('main')`, no manifest `$$`

The semantic view materialization calls
`snowflake__create_or_replace_semantic_view()`, which wraps the model body in a
**single** `{% call statement('main') %}` and renders:

`CREATE OR REPLACE SEMANTIC VIEW <relation> <model SQL body>`

The model body is Snowflake’s **structured** semantic DDL (`TABLES(...)`,
`DIMENSIONS(...)`, etc.), not a YAML blob inside `AS $$ … $$`. There is **no**
`EXECUTE IMMEDIATE` wrapper in that package’s create path. So it does not hit
the same “manifest inside dollar quotes” shape as
`CREATE ORGANIZATION LISTING … AS $$ … $$`.

### dbt-snowflake Python (Snowpark) models: yes, the sproc body is dollar-quoted

In `dbt-snowflake`’s `SnowflakeAdapter.submit_python_job()` (see
`dbt/adapters/snowflake/impl.py`), dbt builds a **stored procedure** (anonymous
`WITH … AS PROCEDURE` or `CREATE OR REPLACE PROCEDURE`) whose **handler body** is
wrapped as:

```text
AS
$$
<optional telemetry snippet>
<compiled Python model code>
$$
```

That entire string is then passed to the adapter’s `execute()`.

### How dbt-snowflake splits SQL before sending

`SnowflakeConnectionManager._split_queries()` in
`dbt/adapters/snowflake/connections.py` uses
`snowflake.connector.util_text.split_statements(...)` — the **Snowflake Python
connector’s** statement splitter, which is intended to respect **dollar-quoted
string literals** and not treat `;` inside `$$ … $$` as a new statement.

So for **normal** dbt Core + `dbt-snowflake`, Python models are designed so the
**outer** `$$ … $$` around the procedure body is handled by that splitter.

If **your** Python source or generated SQL contains **literal `$$`**
sequences, they can still **close the outer delimiter early** and break the
procedure definition — this is the class of problem described in
[dbt-snowflake issue #909](https://github.com/dbt-labs/dbt-snowflake/issues/909)
(Snowflake dollar-quoted SQL inside the Python string colliding with the
procedure wrapper). That is **delimiter collision**, not “split at dollar signs
because Snowflake hates listings.”

### Why organization listings can still break on Snowflake-hosted dbt

`CREATE ORGANIZATION LISTING … AS $$ <YAML manifest> $$ …` puts a **large
dollar-quoted manifest** in the middle of DDL. If the **execution path** that
runs dbt inside Snowflake **does not** use the same `split_statements` behavior
(or splits differently), you can see **truncated** SQL and errors like
`unexpected '<EOF>'`. This package’s `EXECUTE IMMEDIATE $$ … $$` wrapper is a
**workaround** so the **first** dollar-quote pair spans the whole dynamic DDL,
matching the same idea as “one outer quoted blob” as the Python sproc body.

For a full native dbt fix, the product path should preserve **Snowflake-aware**
statement splitting (or avoid splitting entirely for one-shot DDL) the same way
the open-source connector does.
