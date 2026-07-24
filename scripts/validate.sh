#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDERED_DIR="${ROOT_DIR}/.rendered"

if [[ ! -d "${RENDERED_DIR}" ]]; then
  "${ROOT_DIR}/scripts/render.sh"
fi

if grep -R --line-number -E '\$\{[A-Z0-9_]+\}' "${RENDERED_DIR}"; then
  echo "Unresolved environment variables remain in rendered manifests." >&2
  exit 1
fi

if grep -R --line-number -E 'image:[[:space:]]+.*:(latest|stable)([[:space:]]|$)' "${RENDERED_DIR}"; then
  echo "Mutable image tag detected." >&2
  exit 1
fi

if command -v kubectl >/dev/null 2>&1; then
  kubectl apply --dry-run=client -f "${RENDERED_DIR}" >/dev/null
  echo "kubectl client-side validation passed."
else
  echo "kubectl not found; completed static validation only."
fi
