#!/bin/bash
# Smoke Test Script — Run after every production deploy
# Tests critical payment endpoints to verify service health
# Usage: ./smoke-test.sh <base-url> <build-number>
set -euo pipefail

BASE_URL="${1:?Error: BASE_URL required}"
BUILD_NUMBER="${2:-unknown}"
TIMEOUT=30
FAIL=0

echo "========================================"
echo " Smoke Test — Payment Gateway"
echo " Build: #${BUILD_NUMBER}"
echo " URL: ${BASE_URL}"
echo "========================================"

check() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"

    local actual_status
    actual_status=$(curl -s -o /dev/null -w "%{http_code}"         --connect-timeout 5 --max-time ${TIMEOUT} "${url}" || echo "000")

    if [ "${actual_status}" == "${expected_status}" ]; then
        echo "  ✅ PASS  ${name} (HTTP ${actual_status})"
    else
        echo "  ❌ FAIL  ${name} — Expected ${expected_status}, Got ${actual_status}"
        FAIL=1
    fi
}

echo ""
echo "--- Health & Readiness ---"
check "Liveness probe"    "${BASE_URL}/actuator/health/liveness"  200
check "Readiness probe"   "${BASE_URL}/actuator/health/readiness" 200

echo ""
echo "--- API Endpoints ---"
check "Payment API up"    "${BASE_URL}/api/v1/payment/status"     200
check "Metrics exposed"   "${BASE_URL}/actuator/prometheus"       200

echo ""
if [ ${FAIL} -eq 0 ]; then
    echo "✅ All smoke tests PASSED — Build #${BUILD_NUMBER} healthy"
    exit 0
else
    echo "❌ Smoke tests FAILED — triggering rollback"
    exit 1
fi
