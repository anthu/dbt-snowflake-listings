{{ config(materialized='semantic_view') }}

TABLES(
    {{ ref('stg_tpch_customer') }} AS customers
        (PRIMARY KEY customer_key),
    {{ ref('stg_tpch_orders') }} AS orders
        (PRIMARY KEY order_key),
    {{ ref('stg_tpch_nation') }} AS nations
        (PRIMARY KEY nation_key),
    {{ ref('stg_tpch_region') }} AS regions
        (PRIMARY KEY region_key)
)

RELATIONSHIPS(
    orders (customer_key) REFERENCES customers (customer_key),
    customers (nation_key) REFERENCES nations (nation_key),
    nations (region_key) REFERENCES regions (region_key)
)

DIMENSIONS(
    customers.market_segment STRING COMMENT 'Customer market segment (AUTOMOBILE, BUILDING, etc.)',
    customers.customer_name STRING COMMENT 'Customer full name',
    nations.nation_name STRING COMMENT 'Nation name',
    regions.region_name STRING COMMENT 'World region (AFRICA, AMERICA, ASIA, EUROPE, MIDDLE EAST)',
    orders.order_status STRING COMMENT 'Order fulfillment status (F=Fulfilled, O=Open, P=Partial)',
    orders.order_priority STRING COMMENT 'Order priority level'
)

FACTS(
    customers.account_balance NUMBER COMMENT 'Customer account balance',
    orders.total_price NUMBER COMMENT 'Total order price'
)

METRICS(
    total_revenue AS SUM(orders.total_price) COMMENT 'Total revenue across all orders',
    avg_order_value AS AVG(orders.total_price) COMMENT 'Average order value',
    order_count AS COUNT(orders.order_key) COMMENT 'Number of orders',
    customer_count AS COUNT(DISTINCT customers.customer_key) COMMENT 'Number of distinct customers',
    avg_account_balance AS AVG(customers.account_balance) COMMENT 'Average customer account balance'
)
