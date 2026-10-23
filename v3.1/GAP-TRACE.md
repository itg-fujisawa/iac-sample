# 2章ギャップ対応表（v3 反映箇所）

| No | 観点 | 2章根拠 | v3 の反映箇所 | 状態 |
|---|---|---|---|---|
| 1 | DR 方式 | 項番3・15、D-01 | `dr_mode`（既定 cold）：3-network/main.tf、4-data/cloudsql.tf・spanner.tf、environments/prod-osaka-rebuild、runbooks/dr-rebuild.md | 反映 |
| 2 | バックアップ保全 | 項番11(2)⑤・15(2) | 1-org/backup.tf（大阪 WORM・別 Project・別権限・ボールト）、4-data/backup.tf（SQL バックアップ大阪保管、原本日次複製、Spanner エクスポート） | 反映（ボールトは要検証） |
| 3 | Cloud Armor | 項番17・21 | 5-app-infra/armor.tf（OWASP 9、throttle、rate_based_ban、Adaptive Protection、reCAPTCHA）、edge.tf（X-Robots-Tag） | 反映 |
| 4 | Cloud Run 機能単位・Jobs | 項番2・10 | 5-app-infra/cloudrun.tf（services/jobs の for_each、prod min≥1） | 反映 |
| 4' | アプリ実行基盤（Java/Spring Boot） | 項番2・10・14 | app/（Spring Boot 3.5・Java 21、IAM DB 認証、Spanner、構造化ログ、graceful shutdown、Jobs モード）、ci/cloudbuild/app-deploy.yaml・app-promote.yaml、scripts/app_build.sh | 反映（v3.1） |
| 5 | 構成要素 | 項番3・5・17 | 2-environments（API）、4-data/cache-files.tf（Memorystore・Filestore）、6-observability/ops-vm.tf、2-environments（mig-batch SA）、5-app-infra/model-armor.tf | 反映（Model Armor は要検証） |
| 6 | NW 閉域・分離 | 項番3・17・18 | 3-network（用途別サブネット、FW ポリシー既定拒否、Partner Interconnect、dev 外部接続禁止） | 反映 |
| 7 | SCC Premium・Binary Authorization | 項番17・18・22 | ci/terraform、ci/cloudbuild/app-deploy.yaml、5-app-infra（use_default）、6-observability/scc.tf | 反映（Premium 有効化は組織側操作） |
| 8 | ログ12か月・横断検索 | 項番10・17 | 1-org/audit-logs.tf（400日・ロック・BigQuery 連携・組織シンク） | 反映 |
| 9 | Cloud SQL HA | 項番10(5)・11 | 4-data/cloudsql.tf（stg/prod は REGIONAL 必須） | 反映 |
| 10 | 予算 | 項番17 | 2-environments/budget.tf（stg/prod 必須、通知先必須） | 反映 |
| 11 | Sorry ページ | 項番2・16・51 | 1-org/sorry.tf（大阪・職員更新）、5-app-infra/edge.tf（maintenance_mode）、runbooks/sorry-switch.md | 反映 |
| 12 | Spanner 位置づけ | 項番8(4) | 4-data/spanner.tf（stg/prod 必須、regional 東京固定、fine-grained access） | 反映 |

## 未対応・後続
- Cloud DNS ゾーン：既存ゾーンの棚卸し後に追加（v2 の dns-cutover.md の手順を継承）
- warm DR のアプリ層（大阪 Cloud Run / NEG）：提案外のため v3 では未実装
- Gemini Enterprise Agent Platform：API 有効化のみ。エージェント構成は導入方式の確定後
- CMEK のサービス適用：v2 の KMS 計画を継承（未適用）
