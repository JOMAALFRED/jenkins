#!/bin/bash
# =============================================================================
# sign.sh - Signature d'image Docker avec Cosign
# Usage : ./scripts/sign.sh <IMAGE_DIGEST>
# =============================================================================
set -euo pipefail

IMAGE_DIGEST="${1:?Usage: sign.sh <image@sha256:digest>}"
KEY_PATH="${COSIGN_KEY_PATH:-./cosign.key}"
HOST_DOCKER_SOCKET="${DOCKER_SOCKET:-/var/run/docker.sock}"
ALLOW_INSECURE_REGISTRY="${COSIGN_ALLOW_INSECURE_REGISTRY:-true}"
COSIGN_ARGS=()

if [ "$ALLOW_INSECURE_REGISTRY" = "true" ]; then
  COSIGN_ARGS+=(--allow-insecure-registry)
fi

if [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
  HOST_DOCKER_SOCKET="/run/user/$(id -u)/podman/podman.sock"
fi

echo "[SIGN] Signature de : $IMAGE_DIGEST"
echo "[SIGN] Cle : $KEY_PATH"

if command -v cosign >/dev/null 2>&1; then
  cosign sign \
    "${COSIGN_ARGS[@]}" \
    --key "$KEY_PATH" \
    --yes \
    "$IMAGE_DIGEST"
else
  docker run --rm \
    --user 0:0 \
    --network host \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    -e COSIGN_PASSWORD="${COSIGN_PASSWORD:-}" \
    -v "$HOST_DOCKER_SOCKET":/var/run/docker.sock \
    -v "$PWD":/work \
    -w /work \
    gcr.io/projectsigstore/cosign:latest sign \
    "${COSIGN_ARGS[@]}" \
    --key "$KEY_PATH" \
    --yes \
    "$IMAGE_DIGEST"
fi

echo "[SIGN] Image signee avec succes."
