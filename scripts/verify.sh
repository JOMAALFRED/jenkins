#!/bin/bash
# =============================================================================
# verify.sh - Verification de la signature Cosign avant deploiement
# Usage : ./scripts/verify.sh <IMAGE_DIGEST>
# =============================================================================
set -euo pipefail

IMAGE_DIGEST="${1:?Usage: verify.sh <image@sha256:digest>}"
PUB_KEY="${COSIGN_PUB_KEY:-./cosign.pub}"
HOST_DOCKER_SOCKET="${DOCKER_SOCKET:-/var/run/docker.sock}"

if [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
  HOST_DOCKER_SOCKET="/run/user/$(id -u)/podman/podman.sock"
fi

echo "[VERIFY] Verification de : $IMAGE_DIGEST"
echo "[VERIFY] Cle publique : $PUB_KEY"

if command -v cosign >/dev/null 2>&1; then
  cosign verify \
    --key "$PUB_KEY" \
    "$IMAGE_DIGEST"
else
  docker run --rm \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    -v "$HOST_DOCKER_SOCKET":/var/run/docker.sock \
    -v "$PWD":/work \
    -w /work \
    gcr.io/projectsigstore/cosign:latest verify \
    --key "$PUB_KEY" \
    "$IMAGE_DIGEST"
fi

echo "[VERIFY] Signature valide. Deploiement autorise."
