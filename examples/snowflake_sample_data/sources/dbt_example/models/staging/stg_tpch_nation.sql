SELECT
    N_NATIONKEY   AS nation_key,
    N_NAME        AS nation_name,
    N_REGIONKEY   AS region_key,
    N_COMMENT     AS comment
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION
