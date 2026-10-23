# v2（01〜09）→ v3 移行ガイド

## 対応表

| v2 | v3 | 主な変更 |
|---|---|---|
| 01-bootstrap | 0-bootstrap | 管理 Project を共通1つ（prj-common-iac）に集約。実行SAは環境別に分離 |
| （なし・手作業） | 1-org | 組織ポリシー・フォルダ・audit/backup/sorry Project を IaC 化 |
| 02-foundation | 2-environments | Project 作成を bootstrap から移管。API・SA・予算 |
| 03-network | 3-network | サブネットを map 化、FW ポリシー、Interconnect |
| 04-data | 4-data | Spanner 必須化、Memorystore・Filestore、大阪バックアップ |
| 05-application＋06-edge | 5-app-infra | Cloud Run 複数化、LB・Armor を統合、イメージは CD 所有 |
| 07-observability | 6-observability | サービス別アラート、SCC 通知、運用 VM |
| 08-delivery | ci/ | 番号外へ。Binary Authorization を追加 |
| 09-stg-prod | environments/ ＋ runbooks/promotion.md | 環境は工程ではなくディレクトリで表現 |

## 移行方針

v2 は **実環境未適用**（2026-09-30 時点）のため、原則として **v3 で新規構築** します。State の移行は不要です。

既に v2 で作成済みのリソースがある場合は、Terraform 1.5 の `import` ブロックで v3 の Deployment に取り込みます（Deployment をまたぐ `moved` はできません）。

```hcl
# 例：4-data/imports.tf（取り込み後に削除）
import {
  to = google_sql_database_instance.main
  id = "projects/PROJECT/instances/patent-dev-postgres"
}
```

手順：v3 で Preview（import 予定が表示され、置換が無いことを確認）→ Deploy → v2 側の Deployment は `--delete-policy=ABANDON` で削除（リソースは残す）。

**名前の変更に注意**：v3 は `jpp-{env}-*` 命名です。v2 の `patent-{env}-*` から名前が変わるリソース（Cloud SQL、バケット等）は import ではなく作り直しになります。既存データがある場合は名前を v2 に合わせる変数上書きを検討してください。
