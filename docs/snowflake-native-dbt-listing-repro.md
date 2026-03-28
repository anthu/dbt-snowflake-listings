# Repro: truncated listing DDL on dbt Projects on Snowflake (support / product)

Use this note when opening a **Snowflake support** or **product** case about
**hosted dbt** truncating dollar-quoted DDL for listings (or similar
`CREATE … AS $$ … $$` in a single `statement()`).

## Symptom

- `EXECUTE DBT PROJECT … ARGS = 'run …'` or native dbt run fails on a model that
  runs `CREATE ORGANIZATION LISTING … AS $$ <manifest> $$ …`.
- Snowflake error similar to: `syntax error line 2 at position … unexpected '<EOF>'`.
- Same compiled SQL succeeds in **Snowsight** or **dbt Core** against the same account.

## Hypothesis

The SQL submitted to Snowflake is **split or batched** incorrectly (e.g. on
`;` without fully respecting Snowflake **dollar-quoted** string rules), so only a
**prefix** of the statement is executed.

Open-source **dbt-snowflake** uses `snowflake.connector.util_text.split_statements`
in `SnowflakeConnectionManager._split_queries()` (see dbt-adapters). Hosted dbt
may differ.

## Workaround (package-side)

`dbt_snowflake_listings` wraps listing DDL in **`EXECUTE IMMEDIATE $$ … $$`** so
the outer dollar-quote spans the full dynamic statement.

## Ask Snowflake

1. Confirm whether hosted dbt uses the **same** statement-splitting behavior as
   the Python connector’s `split_statements`.
2. If not, align behavior or document limitations for `CREATE ORGANIZATION LISTING`
   / `ALTER LISTING` with manifest-in-`$$`.

## Minimal repro (conceptual)

1. dbt model with custom materialization that runs one `statement('main')` whose
   body is `CREATE ORGANIZATION LISTING … AS $$ … $$ PUBLISH = TRUE` (no
   `EXECUTE IMMEDIATE`).
2. Deploy as DBT PROJECT; run `run`.
3. Compare with executing the **same** SQL text as a single statement in Worksheets.

Attach **query history** / `SYSTEM$GET_DBT_LOG` output for the failed job.
