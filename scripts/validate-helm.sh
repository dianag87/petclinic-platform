#!/usr/bin/env bash
# Validate the petclinic-service Helm chart for all 8 services across dev and prod.
#
# Steps:
#   1. helm lint the chart
#   2. helm template each service x env combo
#   3. kubectl apply --dry-run=client on rendered output
#
# Usage:
#   ./scripts/validate-helm.sh
set -euo pipefail

CHART="helm/petclinic-service"
VALUES_DIR="helm-values"
SERVICES=(
  config-server
  discovery-server
  api-gateway
  customers-service
  visits-service
  vets-service
  genai-service
  admin-server
)
ENVS=(dev prod)
NAMESPACES=(petclinic-dev petclinic-prod)

PASS=0
FAIL=0

log_pass() { echo "  [PASS] $*"; ((PASS++)) || true; }
log_fail() { echo "  [FAIL] $*"; ((FAIL++)) || true; }

echo "========================================"
echo " Petclinic Helm Validation"
echo "========================================"
echo ""

# ─── 1. helm lint ────────────────────────────────────────────────────────────
echo "--- helm lint ---"
if helm lint "$CHART" -f "$VALUES_DIR/config-server.yaml" -f "$VALUES_DIR/dev.yaml" --quiet 2>&1; then
  log_pass "helm lint"
else
  log_fail "helm lint"
fi
echo ""

# ─── 2 & 3. helm template + kubectl dry-run ──────────────────────────────────
for i in "${!ENVS[@]}"; do
  ENV="${ENVS[$i]}"
  NS="${NAMESPACES[$i]}"

  echo "--- environment: $ENV (namespace: $NS) ---"

  for SVC in "${SERVICES[@]}"; do
    # helm template
    RENDERED=$(helm template "$SVC" "$CHART" \
      -f "$VALUES_DIR/$SVC.yaml" \
      -f "$VALUES_DIR/$ENV.yaml" \
      --namespace "$NS" 2>&1) || { log_fail "helm template $SVC ($ENV): $RENDERED"; continue; }

    # kubectl dry-run
    DRY=$(echo "$RENDERED" | kubectl apply --dry-run=client -f - 2>&1) || {
      log_fail "kubectl dry-run $SVC ($ENV): $DRY"
      continue
    }
    log_pass "$SVC ($ENV)"
  done
  echo ""
done

# ─── Summary ─────────────────────────────────────────────────────────────────
echo "========================================"
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "========================================"

[[ $FAIL -eq 0 ]]
