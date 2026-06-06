#!/usr/bin/env bash
# Install the External Secrets Operator on EKS via Helm.
#
# Prerequisites:
#   - kubectl configured for the target cluster (aws eks update-kubeconfig ...)
#   - helm CLI installed
#   - Terraform applied for the secrets module (creates the ESO IRSA role)
#
# Usage:
#   ./scripts/install-eso.sh --env dev [--region us-east-1]
set -euo pipefail

ENV=""
REGION="us-east-1"
CHART_VERSION="0.9.11"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)    ENV="$2";    shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$ENV" ]]; then
  echo "Usage: $0 --env <dev|prod> [--region us-east-1]"
  exit 1
fi

TF_DIR="$(cd "$(dirname "$0")/../terraform/environments/${ENV}" && pwd)"
K8S_DIR="$(cd "$(dirname "$0")/../k8s/base/external-secrets" && pwd)"

echo "Reading Terraform outputs from ${TF_DIR}..."
ESO_ROLE_ARN=$(terraform -chdir="$TF_DIR" output -raw eso_role_arn)

echo "ESO Role ARN:  $ESO_ROLE_ARN"
echo "Region:        $REGION"
echo "Chart version: $CHART_VERSION"
echo ""

# ─── 1. Install / Upgrade ESO ────────────────────────────────────────────────
echo "Installing external-secrets..."
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update external-secrets

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --version "${CHART_VERSION}" \
  --set installCRDs=true \
  --set serviceAccount.name=external-secrets-sa \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${ESO_ROLE_ARN}" \
  --wait

# ─── 2. Apply ClusterSecretStore ─────────────────────────────────────────────
echo "Applying ClusterSecretStore..."
kubectl apply -f "${K8S_DIR}/cluster-secret-store.yaml"

echo ""
echo "External Secrets Operator installed successfully."
echo "Verify with: kubectl get pods -n external-secrets"
echo "Verify store: kubectl get clustersecretstore aws-secrets-manager"
