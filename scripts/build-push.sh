#!/usr/bin/env bash
# Build all 8 Spring Petclinic service images for linux/arm64 and push to ECR.
# Uses Maven to compile JARs, then docker buildx for ARM64 image creation.
#
# Usage:
#   ./scripts/build-push.sh --env dev --tag v1.0.0 [--app-repo ../spring-petclinic-microservices] [--region us-east-1]
set -euo pipefail

ENV=""
TAG=""
APP_REPO="${APP_REPO:-../spring-petclinic-microservices}"
REGION="us-east-1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)      ENV="$2";      shift 2 ;;
    --tag)      TAG="$2";      shift 2 ;;
    --app-repo) APP_REPO="$2"; shift 2 ;;
    --region)   REGION="$2";   shift 2 ;;
    *)
      echo "Usage: $0 --env <dev|prod> --tag <tag> [--app-repo <path>] [--region <region>]" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ENV" || -z "$TAG" ]]; then
  echo "Error: --env and --tag are required." >&2
  exit 1
fi

if [[ ! -d "$APP_REPO" ]]; then
  echo "Error: Application repo not found at: $APP_REPO" >&2
  exit 1
fi

APP_REPO=$(cd "$APP_REPO" && pwd)

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Returns "maven-module:port" for a given service name.
# case statement avoids associative arrays, which require bash 4+ (macOS ships bash 3.2).
module_info() {
  case "$1" in
    config-server)     echo "spring-petclinic-config-server:8888" ;;
    discovery-server)  echo "spring-petclinic-discovery-server:8761" ;;
    api-gateway)       echo "spring-petclinic-api-gateway:8080" ;;
    customers-service) echo "spring-petclinic-customers-service:8081" ;;
    visits-service)    echo "spring-petclinic-visits-service:8082" ;;
    vets-service)      echo "spring-petclinic-vets-service:8083" ;;
    genai-service)     echo "spring-petclinic-genai-service:8084" ;;
    admin-server)      echo "spring-petclinic-admin-server:9090" ;;
    *) echo "" ;;
  esac
}

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

echo "==> Building JARs with Maven (skip tests)"
(cd "$APP_REPO" && ./mvnw clean package -DskipTests --no-transfer-progress)

echo "==> Setting up docker buildx for linux/arm64"
docker buildx inspect petclinic-builder &>/dev/null \
  || docker buildx create --name petclinic-builder --use
docker buildx use petclinic-builder

echo "==> Logging into ECR: ${REGISTRY}"
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

DOCKERFILE="${APP_REPO}/docker/Dockerfile"
if [[ ! -f "$DOCKERFILE" ]]; then
  echo "Error: Dockerfile not found at $DOCKERFILE" >&2
  exit 1
fi

FAILED=()

for SERVICE in "${SERVICES[@]}"; do
  INFO=$(module_info "$SERVICE")
  MODULE="${INFO%%:*}"
  PORT="${INFO##*:}"
  CONTEXT="${APP_REPO}/${MODULE}"
  IMAGE="${REGISTRY}/petclinic-${ENV}/${SERVICE}:${TAG}"

  if [[ ! -d "$CONTEXT" ]]; then
    echo "WARN: Module directory not found, skipping: $CONTEXT"
    FAILED+=("$SERVICE")
    continue
  fi

  # Find the actual JAR (Spring Boot repackager names it with the version, e.g. module-4.0.1.jar)
  JAR_FILE=$(find "${CONTEXT}/target" -maxdepth 1 -name "${MODULE}-*.jar" ! -name "*.original" | head -1)
  if [[ -z "$JAR_FILE" ]]; then
    echo "WARN: JAR not found in ${CONTEXT}/target for ${MODULE}, skipping"
    FAILED+=("$SERVICE")
    continue
  fi
  ARTIFACT_NAME="target/$(basename "$JAR_FILE" .jar)"

  echo "==> Building ${SERVICE} (port ${PORT}) → ${IMAGE}"
  docker buildx build \
    --platform linux/arm64 \
    --file "${DOCKERFILE}" \
    --build-arg ARTIFACT_NAME="${ARTIFACT_NAME}" \
    --build-arg EXPOSED_PORT="${PORT}" \
    --tag "${IMAGE}" \
    --push \
    "${CONTEXT}"
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "ERROR: The following services failed or were skipped: ${FAILED[*]}" >&2
  exit 1
fi

echo ""
echo "All 8 images pushed to ECR (${ENV}, tag: ${TAG})."
echo "Registry: ${REGISTRY}/petclinic-${ENV}/<service>:${TAG}"
