-- =============================================================================
-- Bootstrap: database + egress for dbt deps (native dbt / DCM + DEFINE DBT PROJECT)
-- =============================================================================
-- Run in Snowflake Worksheets or: snow sql --connection <name> -f setup.sql
--
-- Prerequisites: role with CREATE DATABASE, CREATE INTEGRATION, CREATE NETWORK RULE,
-- and ability to grant USAGE on the integration (typically ACCOUNTADMIN).
--
-- Docs:
--   https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake
--   https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-overview
--   https://docs.snowflake.com/en/LIMITEDACCESS/dcm-projects/dcm-projects-early-access
--
-- Some DCM + dbt features are limited access / private preview — adjust to your account.
-- EAI enables outbound HTTPS; keep VALUE_LIST minimal.
-- =============================================================================

-- EDIT: session role if needed (not used in Snowpark notebooks per project rules)
-- USE ROLE ACCOUNTADMIN;

-- Must match sources/dbt_example/profiles.yml database for the dev/local targets
CREATE DATABASE IF NOT EXISTS MY_LISTING_DB;

CREATE NETWORK RULE IF NOT EXISTS DBT_PACKAGES_NETWORK_RULE
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = (
        'hub.getdbt.com:443',
        'github.com:443',
        'codeload.github.com:443'
    );

-- EDIT: integration name must match snow dbt deploy --external-access-integration / DBT PROJECT DDL
CREATE EXTERNAL ACCESS INTEGRATION IF NOT EXISTS DBT_PACKAGES_ACCESS
    ALLOWED_NETWORK_RULES = (DBT_PACKAGES_NETWORK_RULE)
    ENABLED = TRUE;

-- EDIT: role that runs EXECUTE DBT PROJECT / snow dbt deploy / DCM deploy
-- Example: ACCOUNTADMIN or your Snow CLI connection role
GRANT USAGE ON INTEGRATION DBT_PACKAGES_ACCESS TO ROLE ACCOUNTADMIN;

-- Optional: grant database usage to the same role (if not already implied)
-- GRANT USAGE ON DATABASE MY_LISTING_DB TO ROLE <YOUR_ROLE>;

-- Warehouse: create a warehouse separately; tasks and dbt runs need COMPUTE_WH or equivalent.
