#!/bin/bash
# =============================================================================
# verify.sh - Verification de la signature Cosign avant deploiement
# Usage : ./scripts/verify.sh <IMAGE_DIGEST>
# =============================================================================
set -euo pipefail

IMAGE_DIGEST="${1:?Usage: verify.sh <image@sha256:digest>}"
PUB_KEY="${COSIGN_PUB_KEY:-./cosign.pub}"
HOST_DOCKER_SOCKET="${DOCKER_SOCKET:-/var/run/docker.sock}"
ALLOW_INSECURE_REGISTRY="${COSIGN_ALLOW_INSECURE_REGISTRY:-true}"
COSIGN_REGISTRY_ALIAS="${COSIGN_REGISTRY_ALIAS:-host.containers.internal:8090}"
COSIGN_ARGS=()

if [ "$ALLOW_INSECURE_REGISTRY" = "true" ]; then
  COSIGN_ARGS+=(--allow-insecure-registry)
  COSIGN_ARGS+=(--allow-http-registry)
fi

if [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
  HOST_DOCKER_SOCKET="/run/user/$(id -u)/podman/podman.sock"
fi

COSIGN_IMAGE_DIGEST="$IMAGE_DIGEST"
if [ -n "$COSIGN_REGISTRY_ALIAS" ]; then
  COSIGN_IMAGE_DIGEST="${COSIGN_IMAGE_DIGEST/#localhost:8090/$COSIGN_REGISTRY_ALIAS}"
fi

echo "[VERIFY] Verification de : $COSIGN_IMAGE_DIGEST"
echo "[VERIFY] Cle publique : $PUB_KEY"

if command -v cosign >/dev/null 2>&1; then
  cosign verify \
    "${COSIGN_ARGS[@]}" \
    --key "$PUB_KEY" \
    "$COSIGN_IMAGE_DIGEST"
else
  docker run --rm \
    --user 0:0 \
    --network host \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    -e COSIGN_PASSWORD="${COSIGN_PASSWORD:-}" \
    -v "$HOST_DOCKER_SOCKET":/var/run/docker.sock \
    -v "$PWD":/work \
    -w /work \
    gcr.io/projectsigstore/cosign:latest verify \
    "${COSIGN_ARGS[@]}" \
    --key "$PUB_KEY" \
    "$COSIGN_IMAGE_DIGEST"
fi

echo "[VERIFY] Signature valide. Deploiement autorise."
