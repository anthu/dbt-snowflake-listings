{% macro grant_listing_privileges(role, listing_type='organization', privileges=none) %}
    {#
        Grants privileges required for creating/managing listings to a role.

        listing_type: 'organization' (default) for internal marketplace listings,
                      'external' for public Snowflake Marketplace listings.

        Usage:
            dbt run-operation dbt_snowflake_listings.grant_listing_privileges \
                --args '{role: MY_LISTING_ROLE}'

            dbt run-operation dbt_snowflake_listings.grant_listing_privileges \
                --args '{role: MY_LISTING_ROLE, listing_type: external}'

            dbt run-operation dbt_snowflake_listings.grant_listing_privileges \
                --args '{role: MY_LISTING_ROLE, privileges: ["CREATE ORGANIZATION LISTING", "CREATE SHARE"]}'
    #}
    {% if not role %}
        {{ exceptions.raise_compiler_error("role is required") }}
    {% endif %}

    {% if listing_type == 'external' %}
        {% set default_privileges = [
            'CREATE LISTING',
            'CREATE SHARE'
        ] %}
    {% else %}
        {% set default_privileges = [
            'CREATE ORGANIZATION LISTING',
            'IMPORT ORGANIZATION LISTING',
            'CREATE SHARE'
        ] %}
    {% endif %}
    {% set grants = privileges if privileges else default_privileges %}

    {% for privilege in grants %}
        {{ dbt_snowflake_listings._log_action('GRANT', privilege, 'TO ROLE ' ~ role) }}
        {% call statement('grant_' ~ loop.index, fetch_result=false) %}
            GRANT {{ privilege }} ON ACCOUNT TO ROLE {{ role }}
        {% endcall %}
    {% endfor %}
{% endmacro %}
