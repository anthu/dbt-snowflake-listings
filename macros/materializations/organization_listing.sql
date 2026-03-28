{% materialization organization_listing, adapter='snowflake' %}

    {# ── 1. Read config from meta (dbt 1.11+ requires custom keys in meta) ── #}

    {% set meta = config.get('meta', {}) %}
    {% set share_name = meta.get('share_name') %}
    {% set listing_manifest = meta.get('listing_manifest', {}) %}
    {% set listing_name = meta.get('listing_name', model.name | upper) %}
    {% set publish = meta.get('publish', true) %}
    {% set secure_objects_only = meta.get('secure_objects_only', false) %}

    {# ── 2. Validate required config ────────────────────────────────────────── #}

    {% if not share_name %}
        {{ exceptions.raise_compiler_error(
            "organization_listing materialization requires 'share_name' in meta config. "
            "Set it in config(meta={'share_name': '...'}) or in the .yml file under config.meta.share_name."
        ) }}
    {% endif %}

    {% if not listing_manifest %}
        {{ exceptions.raise_compiler_error(
            "organization_listing materialization requires 'listing_manifest' in meta config. "
            "Define it in the .yml schema file under config.meta.listing_manifest."
        ) }}
    {% endif %}

    {% if not listing_manifest.get('title') %}
        {{ exceptions.raise_compiler_error(
            "listing_manifest.title is required. Add a 'title' key to your listing_manifest."
        ) }}
    {% endif %}

    {% if not listing_manifest.get('organization_targets') %}
        {{ exceptions.raise_compiler_error(
            "listing_manifest.organization_targets is required. "
            "Add 'organization_targets' with 'access' or 'discovery' targets."
        ) }}
    {% endif %}

    {# ── 3. Parse share objects from compiled SQL ───────────────────────────── #}

    {% set share_objects = dbt_snowflake_listings._parse_share_objects(sql) %}

    {% if share_objects | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "No share objects found in model '" ~ model.name ~ "'. "
            "Use share_model(ref(...)) or share_models([ref(...), ...]) "
            "in the model body to declare objects to share."
        ) }}
    {% endif %}

    {# ── 4. Serialize the manifest dict to YAML ────────────────────────────── #}

    {% set manifest_yaml = dbt_snowflake_listings._serialize_manifest(listing_manifest) %}

    {% if execute %}

    {{ dbt_snowflake_listings._log_action('MATERIALIZING', 'ORGANIZATION LISTING', listing_name) }}

    {# ── 5. Handle --full-refresh: drop everything and start fresh ─────────── #}

    {% if flags.FULL_REFRESH %}

        {% if dbt_snowflake_listings._listing_exists(listing_name) %}
            {{ dbt_snowflake_listings._log_action('FULL REFRESH', 'LISTING', listing_name, 'dropping and recreating') }}

            {# Check listing state -- only unpublish if currently published #}
            {% set show_result = run_query("SHOW LISTINGS LIKE '" ~ listing_name ~ "'") %}
            {% if show_result | length > 0 %}
                {% set state = show_result.columns['state'].values()[0] | default('') | upper %}
                {% if state not in ('DRAFT', 'UNPUBLISHED', '') %}
                    {% call statement('unpublish_for_refresh', fetch_result=false) %}
                        ALTER LISTING {{ listing_name }} UNPUBLISH
                    {% endcall %}
                {% endif %}
            {% endif %}

            {% call statement('drop_listing_refresh', fetch_result=false) %}
                DROP LISTING {{ listing_name }}
            {% endcall %}
        {% endif %}

        {% call statement('drop_share_refresh', fetch_result=false) %}
            DROP SHARE IF EXISTS {{ share_name }}
        {% endcall %}

    {% endif %}

    {# ── 6. Create share and grant objects ──────────────────────────────────── #}

    {{ dbt_snowflake_listings._create_share(share_name, share_objects, secure_objects_only) }}

    {# ── 7. Create or alter the listing ─────────────────────────────────────── #}

    {% set listing_exists = dbt_snowflake_listings._listing_exists(listing_name) %}

    {% if not listing_exists %}

        {{ dbt_snowflake_listings._log_action('CREATE', 'ORGANIZATION LISTING', listing_name) }}

        {# EXECUTE IMMEDIATE $$...$$: native dbt on Snowflake can split on ';' before the
           manifest $$ block, truncating CREATE ORGANIZATION LISTING. Outer $$ keeps one batch. #}
        {% call statement('main', fetch_result=false) %}
            EXECUTE IMMEDIATE $$
            CREATE ORGANIZATION LISTING {{ listing_name }}
            SHARE {{ share_name }}
            AS
            $DBT_SL_MANIFEST$
{{ manifest_yaml }}
$DBT_SL_MANIFEST$
            PUBLISH = {{ publish | upper }};
            $$;
        {% endcall %}

    {% else %}

        {{ dbt_snowflake_listings._log_action('ALTER', 'ORGANIZATION LISTING', listing_name) }}

        {% call statement('main', fetch_result=false) %}
            EXECUTE IMMEDIATE $$
            ALTER LISTING {{ listing_name }}
            AS
            $DBT_SL_MANIFEST$
{{ manifest_yaml }}
$DBT_SL_MANIFEST$
            ;
            $$;
        {% endcall %}

        {% if publish %}
            {{ dbt_snowflake_listings._log_action('PUBLISH', 'LISTING', listing_name) }}
            {% call statement('publish_listing', fetch_result=false) %}
                ALTER LISTING {{ listing_name }} PUBLISH
            {% endcall %}
        {% else %}
            {{ dbt_snowflake_listings._log_action('UNPUBLISH', 'LISTING', listing_name) }}
            {% call statement('unpublish_listing', fetch_result=false) %}
                ALTER LISTING {{ listing_name }} UNPUBLISH
            {% endcall %}
        {% endif %}

    {% endif %}

    {{ dbt_snowflake_listings._log_action('DONE', 'ORGANIZATION LISTING', listing_name) }}

    {% endif %}

    {{ return({'relations': []}) }}

{% endmaterialization %}
