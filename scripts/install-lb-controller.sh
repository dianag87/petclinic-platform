#!/usr/bin/env bash
# Install the AWS Load Balancer Controller on EKS via Helm.
#
# Prerequisites:
#   - kubectl configured for the target cluster (aws eks update-kubeconfig ...)
#   - helm CLI installed
#   - Terraform applied for the dns module (creates the IRSA role)
#
# Usage:
#   ./scripts/install-lb-controller.sh --env dev [--region us-east-1]
set -euo pipefail

ENV=""
REGION="us-east-1"
CHART_VERSION="3.3.0"

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

echo "Reading Terraform outputs from ${TF_DIR}..."
CLUSTER_NAME=$(terraform -chdir="$TF_DIR" output -raw eks_cluster_name)
LB_ROLE_ARN=$(terraform -chdir="$TF_DIR" output -raw lb_controller_role_arn)
VPC_ID=$(terraform -chdir="$TF_DIR" output -raw vpc_id)

echo "Cluster:       $CLUSTER_NAME"
echo "LB Role ARN:   $LB_ROLE_ARN"
echo "VPC ID:        $VPC_ID"
echo "Region:        $REGION"
echo "Chart version: $CHART_VERSION"
echo ""

# ─── 1. Apply CRDs ──────────────────────────────────────────────────────────
# Uses helm show crds to fetch CRDs for the exact chart version being installed,
# avoiding any GitHub URL versioning mismatch.
echo "Applying CRDs for chart version ${CHART_VERSION}..."
helm repo add eks https://aws.github.io/eks-charts 2>/dev/null || true
helm repo update eks
helm show crds eks/aws-load-balancer-controller --version "${CHART_VERSION}" | kubectl apply -f -

# ─── 2. Install / Upgrade Controller ────────────────────────────────────────
echo "Installing aws-load-balancer-controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version "${CHART_VERSION}" \
  --set clusterName="${CLUSTER_NAME}" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${LB_ROLE_ARN}" \
  --set region="${REGION}" \
  --set vpcId="${VPC_ID}" \
  --wait

echo ""
echo "AWS Load Balancer Controller installed successfully."
echo "Verify with: kubectl get deployment -n kube-system aws-load-balancer-controller"
