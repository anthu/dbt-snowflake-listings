{%- macro listing_ref(listing_name, object_model) -%}
{#-
    Returns a ULL-based reference to an object within an organizational listing.
    Use this for portable models that work identically whether you're the
    listing producer or a consumer.

    Args:
        listing_name: The listing identifier (string), e.g. 'MY_LISTING'
        object_model: A ref() to the upstream model shared in the listing

    Usage:
        SELECT * FROM {{ listing_ref('MY_LISTING', ref('my_table')) }}
        -- resolves to: "orgdatacloud$internal$MY_LISTING".PUBLIC.MY_TABLE
-#}
"orgdatacloud$internal${{ listing_name | upper }}".{{ object_model.schema }}.{{ object_model.identifier }}
{%- endmacro -%}
