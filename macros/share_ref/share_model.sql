{%- macro share_model(relation) -%}
-- SHARE_OBJECT|{{ relation.database }}|{{ relation.schema }}|{{ relation.identifier }}
{%- endmacro -%}
