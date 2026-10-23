#!/usr/bin/env bash
# app/（Spring Boot）をビルド・脆弱性ゲート・署名し、digest を 5-app-infra.tfvars に書き込む
#   scripts/app_build.sh <dev|stg> [--deploy]
#   - 初回（Cloud Run 作成前）：--deploy なし → tfvars 更新 → scripts/im.sh preview/apply <env> 5-app-infra
#   - 2回目以降：通常は Cloud Build トリガー（app-deploy.yaml）を使う
#   prod は app-promote.yaml（stg と同一 digest）を使うため、このスクリプトでは扱わない
set -euo pipefail
cd "$(dirname "$0")/.."
ENV="${1:?dev|stg}"; DEPLOY="false"; [ "${2:-}" = "--deploy" ] && DEPLOY="true"
case "$ENV" in dev|stg) ;; prod) echo "prod は ci/cloudbuild/app-promote.yaml を使用"; exit 2 ;; *) exit 2 ;; esac

TFVARS="environments/${ENV}/5-app-infra.tfvars"
PROJECT=$(grep -E '^project_id' "$TFVARS" | sed -E 's/.*"(.*)".*/\1/')
[[ "$PROJECT" == REPLACE* ]] && { echo "ERROR: $TFVARS の project_id を設定してください"; exit 3; }
REGION="asia-northeast1"
TAG="$(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo local)"
SA="projects/${PROJECT}/serviceAccounts/app-builder@${PROJECT}.iam.gserviceaccount.com"

gcloud builds submit . \
  --project="$PROJECT" --region="$REGION" \
  --config=ci/cloudbuild/app-deploy.yaml \
  --service-account="$SA" \
  --gcs-source-staging-dir="gs://${PROJECT}-build-src/source" \
  --substitutions="_ENV=${ENV},_TAG=${TAG},_DEPLOY=${DEPLOY}"

DIGEST=$(gcloud artifacts docker images describe \
  "${REGION}-docker.pkg.dev/${PROJECT}/jpp-${ENV}-app/app:${TAG}" \
  --format='value(image_summary.fully_qualified_digest)')
echo "built: $DIGEST"

python3 - "$TFVARS" "$DIGEST" <<'PY'
import re, sys
path, digest = sys.argv[1], sys.argv[2]
s = open(path, encoding="utf-8").read()
s2, n = re.subn(r'"[^"]*/app@sha256:[0-9a-f]{64}"', '"%s"' % digest, s)
open(path, "w", encoding="utf-8").write(s2)
print(f"updated {n} image(s) in {path}")
PY
echo "次：scripts/im.sh preview ${ENV} 5-app-infra（初回）"
