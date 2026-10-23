#!/usr/bin/env bash
# Infrastructure Manager の Preview / Apply ラッパー
#   scripts/im.sh preview <env|common> <stage>
#   scripts/im.sh apply   <env|common> <stage>
# stage: 1-org | 2-environments | 3-network | 4-data | 5-app-infra | 6-observability | ci
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f scripts/im.env ] && source scripts/im.env

ACTION="${1:?preview|apply}"; ENV="${2:?env}"; STAGE="${3:?stage}"
: "${IAC_PROJECT:?}"; : "${IM_LOCATION:=asia-northeast1}"

case "$STAGE" in
  1-org) [ "$ENV" = "common" ] || { echo "1-org は common で実行"; exit 2; }; SRC="1-org"; SA_KEY="org" ;;
  2-environments|3-network|4-data|5-app-infra|6-observability) SRC="$STAGE"; SA_KEY="$ENV" ;;
  ci) SRC="ci/terraform"; SA_KEY="$ENV" ;;
  *) echo "unknown stage: $STAGE"; exit 2 ;;
esac
case "$ENV" in common|dev|stg|prod) ;; *) echo "unknown env: $ENV"; exit 2 ;; esac

INPUTS="environments/${ENV}/${STAGE}.tfvars"
[ -f "$INPUTS" ] || { echo "missing $INPUTS"; exit 2; }
if grep -q "REPLACE" "$INPUTS"; then
  echo "ERROR: $INPUTS に REPLACE が残っています"; exit 3
fi

NAME="jpp-${ENV}-${STAGE}"
SA="projects/${IAC_PROJECT}/serviceAccounts/im-${SA_KEY}@${IAC_PROJECT}.iam.gserviceaccount.com"
DEP="projects/${IAC_PROJECT}/locations/${IM_LOCATION}/deployments/${NAME}"
COMMIT="${COMMIT_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo local)}"
LABELS="commit=${COMMIT,,},env=${ENV},stage=${STAGE//[^a-z0-9-]/-}"

if [ "$ACTION" = "apply" ] && [ "$ENV" = "prod" ] && [ -z "${BUILD_ID:-}" ]; then
  echo "ERROR: prod の apply は CI（承認付き Cloud Build）からのみ実行できます"; exit 4
fi

case "$ACTION" in
  preview)
    PREVIEW="pv-${ENV}-${STAGE//[^a-z0-9-]/-}-$(date +%Y%m%d%H%M%S)"
    gcloud infra-manager previews create "projects/${IAC_PROJECT}/locations/${IM_LOCATION}/previews/${PREVIEW}" \
      --deployment="${DEP}" --service-account="${SA}" \
      --local-source="${SRC}" --inputs-file="${INPUTS}" --labels="${LABELS}"
    mkdir -p generated/previews
    gcloud infra-manager previews export "projects/${IAC_PROJECT}/locations/${IM_LOCATION}/previews/${PREVIEW}" \
      --file="generated/previews/${PREVIEW}"
    if [ -n "${EVIDENCE_BUCKET:-}" ]; then
      gcloud storage cp "generated/previews/${PREVIEW}"* "gs://${EVIDENCE_BUCKET}/previews/${ENV}/${STAGE}/"
    fi
    echo "Preview: ${PREVIEW}（差分をレビューしてから apply）"
    ;;
  apply)
    : "${CHANGE_ID:?CHANGE_ID（変更管理番号）を設定してください}"
    gcloud infra-manager deployments apply "${DEP}" \
      --service-account="${SA}" --local-source="${SRC}" --inputs-file="${INPUTS}" \
      --labels="${LABELS},change=${CHANGE_ID,,}"
    gcloud infra-manager deployments describe "${DEP}" --format=json > "generated/${NAME}-$(date +%Y%m%d%H%M%S).json" || true
    ;;
  *) echo "unknown action"; exit 2 ;;
esac
