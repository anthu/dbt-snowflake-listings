SELECT
    C_CUSTKEY     AS customer_key,
    C_NAME        AS customer_name,
    C_ADDRESS     AS address,
    C_NATIONKEY   AS nation_key,
    C_PHONE       AS phone,
    C_ACCTBAL     AS account_balance,
    C_MKTSEGMENT  AS market_segment,
    C_COMMENT     AS comment
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER
LIMIT 5000
