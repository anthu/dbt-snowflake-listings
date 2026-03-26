#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=== Installing dependencies ==="
dbt deps

echo ""
echo "=== Creating database (if needed) ==="
dbt run-operation create_test_db 2>/dev/null || true

echo ""
echo "=== Run 1: Create path (staging tables + listing) ==="
dbt run

echo ""
echo "=== Running data tests ==="
dbt test

echo ""
echo "=== Run 2: Alter path (idempotency test) ==="
dbt run

echo ""
echo "=== Run 3: Full refresh path (drop + recreate) ==="
dbt run --full-refresh

echo ""
echo "=== Cleanup: Drop listing and share ==="
dbt run-operation cleanup_test_listing

echo ""
echo "=== All integration tests passed ==="
