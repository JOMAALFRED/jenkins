#!/bin/bash
# =============================================================================
# scan.sh - Scan de vulnerabilites avec Trivy
# Usage : ./scripts/scan.sh <IMAGE_NAME>
# =============================================================================
set -euo pipefail

IMAGE="${1:-localhost:5000/devsecops/fastapi-demo:latest}"
TRIVY_SERVER="${TRIVY_SERVER_URL:-http://localhost:4954}"
SEVERITY="${SCAN_SEVERITY:-CRITICAL,HIGH}"
OUTPUT_FORMAT="${SCAN_FORMAT:-table}"
HOST_DOCKER_SOCKET="${DOCKER_SOCKET:-/var/run/docker.sock}"

if [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
  HOST_DOCKER_SOCKET="/run/user/$(id -u)/podman/podman.sock"
fi

echo "[SCAN] Image : $IMAGE"
echo "[SCAN] Seuil : $SEVERITY"

if command -v trivy >/dev/null 2>&1; then
  echo "[SCAN] Mode : trivy local"
  echo "[SCAN] Serveur Trivy : $TRIVY_SERVER"
  trivy image \
    --server "$TRIVY_SERVER" \
    --severity "$SEVERITY" \
    --ignore-unfixed \
    --exit-code 1 \
    --format "$OUTPUT_FORMAT" \
    --output "trivy-report.txt" \
    "$IMAGE"
else
  echo "[SCAN] Mode : conteneur aquasec/trivy"
  docker run --rm \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    -v "$HOST_DOCKER_SOCKET":/var/run/docker.sock \
    -v trivy_cache:/root/.cache/trivy \
    aquasec/trivy:latest image \
    --severity "$SEVERITY" \
    --ignore-unfixed \
    --exit-code 1 \
    --format "$OUTPUT_FORMAT" \
    "$IMAGE" | tee "trivy-report.txt"
fi

echo "[SCAN] OK - Aucune vulnerabilite $SEVERITY detectee."
