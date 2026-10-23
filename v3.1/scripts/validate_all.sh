#!/usr/bin/env bash
# terraform 1.5.7 がある環境での検査（provider 取得のためネットワーク必要）
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/static_check.py
for d in 0-bootstrap 1-org 2-environments 3-network 4-data 5-app-infra 6-observability ci/terraform; do
  echo "== $d"
  terraform -chdir="$d" fmt -check -recursive
  terraform -chdir="$d" init -backend=false -input=false >/dev/null
  terraform -chdir="$d" validate
done
