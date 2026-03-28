#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RUN_SUFFIX="${DBT_TEST_RUN_ID:-$(date +%Y%m%d%H%M%S)}"
LISTING_NAME="TEST_ORG_LISTING_${RUN_SUFFIX}"
SHARE_NAME="DBT_MARKETPLACE_TEST_SHARE_${RUN_SUFFIX}"
DBT_VARS="{integration_listing_name: ${LISTING_NAME}, integration_share_name: ${SHARE_NAME}}"

cd "$PROJECT_DIR"

cleanup() {
  echo ""
  echo "=== Cleanup: Drop listing and share ==="
  dbt run-operation cleanup_test_listing --vars "$DBT_VARS" || true
}

trap cleanup EXIT

echo "=== Integration run identifiers ==="
echo "Listing: ${LISTING_NAME}"
echo "Share:   ${SHARE_NAME}"
echo ""

echo "=== Installing dependencies ==="
dbt deps

echo ""
echo "=== Creating database (if needed) ==="
dbt run-operation create_test_db

echo ""
echo "=== Run 1: Create path (staging tables + listing) ==="
dbt run --vars "$DBT_VARS"

echo ""
echo "=== Running data tests ==="
dbt test --vars "$DBT_VARS"

echo ""
echo "=== Run 2: Alter path (idempotency test) ==="
dbt run --vars "$DBT_VARS"

echo ""
echo "=== Run 3: Full refresh path (drop + recreate) ==="
dbt run --full-refresh --vars "$DBT_VARS"

echo ""
echo "=== All integration tests passed ==="
