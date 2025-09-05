#!/usr/bin/env bash
set -euo pipefail
KUSTOMIZE_FILE="deploy/overlays/prod/kustomization.yaml"
IMAGE="$1"   # e.g. myregistry.azurecr.io/profile-site:123
if ! command -v yq >/dev/null 2>&1; then
  # simple sed fallback for "newName" and "newTag"
  REG="${IMAGE%%:*}"
  TAG="${IMAGE##*:}"
  sed -i.bak "s|newName:.*|newName: ${REG}|" "$KUSTOMIZE_FILE"
  sed -i.bak "s|newTag:.*|newTag: ${TAG}|" "$KUSTOMIZE_FILE"
else
  yq -i "
    (.images[] | select(.name == "profile-site") .newName) = "${IMAGE%%:*}" |
    (.images[] | select(.name == "profile-site") .newTag)  = "${IMAGE##*:}"
  " "$KUSTOMIZE_FILE"
fi
echo "Updated $KUSTOMIZE_FILE to image=$IMAGE"
