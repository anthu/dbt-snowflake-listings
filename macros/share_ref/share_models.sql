{%- macro share_models(relations) -%}
{%- for relation in relations -%}
{{ dbt_snowflake_listings.share_model(relation) }}
{% endfor -%}
{%- endmacro -%}
