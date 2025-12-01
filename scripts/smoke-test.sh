#!/usr/bin/env bash
# Verify a deployed cell end-to-end:
#   1. Frontend loads (HTTP 200 from CloudFront/S3)
#   2. POST /api/items creates an item (HTTP 201 via Lambda)
#   3. GET /api/items returns the created item (DynamoDB round-trip)
#
# Usage: ./scripts/smoke-test.sh <cloudfront-url>
#   Example: ./scripts/smoke-test.sh https://d1234abcd.cloudfront.net
set -euo pipefail

URL="${1:-}"
if [ -z "$URL" ]; then
  echo "Usage: $0 <cloudfront-url>" >&2
  echo "  Example: $0 https://d1234abcd.cloudfront.net" >&2
  exit 1
fi

URL="${URL%/}"
ITEM_NAME="smoke-$(date +%s)"
PASS=0
FAIL=0

_check() {
  local desc="$1" result="$2"
  if [ "$result" = "ok" ]; then
    echo "  [PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "==> Smoke-testing $URL"

# 1 — Frontend
echo ""
echo "--- Frontend"
STATUS="$(curl -s -o /dev/null -w "%{http_code}" "$URL/")"
_check "GET / returns 200" "$([ "$STATUS" = "200" ] && echo ok || echo fail)"

# 2 — Backend write
echo ""
echo "--- Backend round-trip"
POST_STATUS="$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$ITEM_NAME\"}" \
  "$URL/api/items")"
_check "POST /api/items returns 201" "$([ "$POST_STATUS" = "201" ] && echo ok || echo fail)"

# 3 — Backend read-back
ITEMS="$(curl -s "$URL/api/items")"
_check "GET /api/items contains the created item" \
  "$(echo "$ITEMS" | grep -q "$ITEM_NAME" && echo ok || echo fail)"

# Summary
echo ""
echo "==> Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
