#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"
TEMPLATE_DIR="${ROOT_DIR}/manifests/templates"
OUTPUT_DIR="${ROOT_DIR}/.rendered"

ENV_SUBST_VARS='
${ALERT_EMAIL_TO}
${ALERT_GROUP_INTERVAL}
${ALERT_GROUP_WAIT}
${ALERTMANAGER_CONFIG_B64}
${ALERTMANAGER_IMAGE}
${ALERT_REPEAT_INTERVAL}
${CLUSTER_NAME}
${CRITICAL_REPEAT_INTERVAL}
${KUBE_STATE_METRICS_IMAGE}
${NAMESPACE}
${SCRAPE_INTERVAL}
${SMTP_FROM}
${SMTP_PASSWORD}
${SMTP_REQUIRE_TLS}
${SMTP_SMARTHOST}
${SMTP_USERNAME}
${STORAGE_CLASS}
${VICTORIA_METRICS_IMAGE}
${VMAGENT_IMAGE}
${VMALERT_IMAGE}
${VM_RETENTION}
${VM_STORAGE_SIZE}
'

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Run: cp .env.example .env" >&2
  exit 1
fi

command -v envsubst >/dev/null 2>&1 || {
  echo "envsubst is required (package: gettext-base)." >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

required_vars=(
  NAMESPACE STORAGE_CLASS VM_STORAGE_SIZE VM_RETENTION SCRAPE_INTERVAL CLUSTER_NAME
  VICTORIA_METRICS_IMAGE VMAGENT_IMAGE VMALERT_IMAGE KUBE_STATE_METRICS_IMAGE ALERTMANAGER_IMAGE
  SMTP_SMARTHOST SMTP_FROM SMTP_USERNAME SMTP_PASSWORD ALERT_EMAIL_TO SMTP_REQUIRE_TLS
  ALERT_GROUP_WAIT ALERT_GROUP_INTERVAL ALERT_REPEAT_INTERVAL CRITICAL_REPEAT_INTERVAL
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Required variable ${var} is empty in ${ENV_FILE}." >&2
    exit 1
  fi
done

if [[ "${SMTP_PASSWORD}" == "replace-me" ]]; then
  echo "SMTP_PASSWORD still has the example value." >&2
  exit 1
fi

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

alertmanager_config="$(
  envsubst "${ENV_SUBST_VARS}" \
    < "${TEMPLATE_DIR}/alertmanager.yml.template"
)"
export ALERTMANAGER_CONFIG_B64
ALERTMANAGER_CONFIG_B64="$(printf '%s' "${alertmanager_config}" | base64 | tr -d '\n')"

for template in "${TEMPLATE_DIR}"/*.yaml; do
  output="${OUTPUT_DIR}/$(basename "${template}")"
  envsubst "${ENV_SUBST_VARS}" < "${template}" > "${output}"
done

chmod 700 "${OUTPUT_DIR}"
chmod 600 "${OUTPUT_DIR}"/*.yaml

echo "Rendered manifests into ${OUTPUT_DIR}"
