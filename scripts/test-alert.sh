#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

kubectl -n "${NAMESPACE}" run alert-test \
  --image=busybox:1.37.0 \
  --restart=Never \
  --labels=k3s-ops-test-alert=true \
  -- /bin/sh -c 'exit 1' || true

echo "A deliberately failing pod was created. The PodFailed test alert should email after its for-duration."
echo "Clean it up with: kubectl -n ${NAMESPACE} delete pod alert-test"
