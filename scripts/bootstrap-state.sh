#!/usr/bin/env bash
# bootstrap-state.sh — provision S3 bucket and DynamoDB table for Terraform remote state
# Run this once before `terraform init`. Safe to re-run (idempotent).
#
# Usage:
#   ./scripts/bootstrap-state.sh [--region us-east-1]

set -euo pipefail

REGION="us-east-1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--region REGION]" >&2
      exit 1
      ;;
  esac
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="petclinic-tfstate-${ACCOUNT_ID}"
TABLE_NAME="petclinic-terraform-locks"

echo "==> Bootstrapping Terraform remote state"
echo "    Account ID : ${ACCOUNT_ID}"
echo "    Region     : ${REGION}"
echo "    S3 Bucket  : ${BUCKET_NAME}"
echo "    DynamoDB   : ${TABLE_NAME}"
echo ""

# ── S3 bucket ──────────────────────────────────────────────────────────────
if aws s3api head-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "[OK] S3 bucket already exists: ${BUCKET_NAME}"
else
  echo "==> Creating S3 bucket: ${BUCKET_NAME}"
  if [[ "${REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  echo "[OK] S3 bucket created"
fi

# Enable versioning
echo "==> Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled
echo "[OK] Versioning enabled"

# Enable server-side encryption (AES256)
echo "==> Enabling server-side encryption (AES256)"
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'
echo "[OK] Server-side encryption enabled"

# Block all public access (4 settings)
echo "==> Blocking all public access on S3 bucket"
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
echo "[OK] Public access blocked"

# ── DynamoDB table ──────────────────────────────────────────────────────────
if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "[OK] DynamoDB table already exists: ${TABLE_NAME}"
else
  echo "==> Creating DynamoDB table: ${TABLE_NAME}"
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"

  echo "==> Waiting for DynamoDB table to become active..."
  aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${REGION}"
  echo "[OK] DynamoDB table created"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Update backend.tf if needed:"
echo "     bucket         = \"${BUCKET_NAME}\""
echo "     dynamodb_table = \"${TABLE_NAME}\""
echo "  2. Run: terraform -chdir=terraform/environments/dev init"
echo "  3. Run: terraform -chdir=terraform/environments/prod init"
