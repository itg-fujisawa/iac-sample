# 次期J-PlatPat Google Cloud IaC v3（Infrastructure Manager）

v2（01〜09）を、**層＝番号（適用順）／環境＝ディレクトリ** の構成に再編し、提案書2章とのギャップ No.1〜12 を反映した版です。

> 状態：コード作成・オフライン静的検査（`scripts/static_check.py`）と Java の構文確認まで実施。`terraform validate`、Maven ビルド、Preview、実クラウドへの適用は未実施です。

## 構成

```
0-bootstrap/        管理Project（prj-common-iac）、実行SA、State（手動で1回）
1-org/              組織ポリシー、fld-dev/stg/prod、prj-common-audit / backup / sorry
2-environments/     環境別 Project、API、用途別SA、予算、SCC 閲覧
3-network/          VPC、用途別サブネット、PSA、FW ポリシー、Interconnect
4-data/             Cloud SQL、Spanner、Memorystore、Filestore、原本 GCS、大阪バックアップ
5-app-infra/        Cloud Run（機能単位）/Jobs、LB、Cloud Armor、CDN、Sorry 切替
6-observability/    アラート、外形監視、SCC 通知、運用管理 VM
ci/terraform/       Artifact Registry、Binary Authorization（署名鍵・attestor・ポリシー）、ビルド権限
ci/cloudbuild/      Preview / Apply / アプリ CD（app-deploy）/ 昇格（app-promote）
app/                Spring Boot アプリ（Java 21、Cloud Run サービス／Jobs 共通イメージ）
environments/       common / dev / stg / prod / prod-osaka-rebuild の tfvars
runbooks/           昇格、DR 再構築、Sorry 切替、障害一次対応
scripts/            im.sh（Infra Manager ラッパー）、static_check.py、validate_all.sh
```

## 適用順

| 順 | Stage | 単位 | 実行SA | 備考 |
|---|---|---|---|---|
| 0 | 0-bootstrap | 1回 | 組織管理者（ローカル） | Terraform CLI |
| 1 | 1-org | common | im-org | `scripts/im.sh preview common 1-org` |
| 2 | 2-environments | env ごと | im-{env} | 出力を 1-org の backup_writers へ → 1-org 再適用 |
| 3 | 3-network | env ごと | im-{env} | |
| 4 | 4-data | env ごと | im-{env} | |
| 5 | ci | env ごと | im-{env} | Registry・Binary Authorization を先に作る |
| 6 | （アプリ初回ビルド） | dev/stg | app-builder | `scripts/app_build.sh <env>` が digest を tfvars に書込み。prod は `app-promote.yaml` |
| 7 | 5-app-infra | env ごと | im-{env} | Cloud Run サービス／Jobs を作成 |
| 8 | 6-observability | env ごと | im-{env} | |

各 Stage は前の Stage の出力を **tfvars に転記** して受け取ります（remote state 参照を持たない＝v2 方針を継承）。

```bash
cp scripts/im.env.example scripts/im.env    # 0-bootstrap の出力を記入
python3 scripts/static_check.py
scripts/im.sh preview dev 3-network
CHANGE_ID=CHG-0101 scripts/im.sh apply dev 3-network   # prod は CI からのみ
```

## 設計上の決定

- **組織あり** を前提（フォルダ単位の権限・組織ポリシー・組織ログシンク）。`fld-mig` は作らない（移行環境なし）
- **prj-backup / prj-audit / prj-sorry は fld-common 配下**：本番と別権限で管理し、環境 Project の障害・誤操作から独立させる
- **イメージの所有者はアプリ CD**：Terraform は Cloud Run の枠（SA・VPC・スケール・環境変数・Binary Authorization）のみ。イメージ更新は `app-deploy.yaml`
- **1イメージ・複数サービス**：同じ Spring Boot イメージを機能単位サービスと Jobs に配備し、`APP_SERVICE` / `APP_JOB_NAME` で役割を切り替える。機能ごとに別アプリへ分ける場合は `services[*].image` を個別に指定
- **DR は cold が既定**：大阪には平時サーバを置かない。warm は提案外オプション（3-network / 4-data のみ実装。アプリ層は v2 の dr.tf を参照）

## 【要検証】箇所（provider 6.50.0 での属性・リソースの有無）

| ファイル | 内容 | 既定 |
|---|---|---|
| 1-org/backup.tf | `google_backup_dr_backup_vault` | 無効（`enable_backup_vault=false`） |
| 5-app-infra/model-armor.tf | `google_model_armor_template` | 無効（`model_armor_enabled=false`） |
| 5-app-infra/cloudrun.tf | `invoker_iam_disabled` | 有効（ドメイン制限共有下で allUsers を使わないため） |

## 解除できない設定

`lock_audit_bucket`（1-org）と `lock_backup_buckets`（1-org）は true にすると戻せません。stg で確認してから有効化してください。

関連：`GAP-TRACE.md`（2章ギャップとの対応）、`MIGRATION.md`（v2 からの移行）、`CHANGELOG.md`
