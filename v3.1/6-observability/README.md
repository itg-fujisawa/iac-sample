# 6-observability：監視・SCC 通知・運用管理 VM

- Cloud Run サービスごとの 5xx・p95 レイテンシ、外形監視、Cloud Armor の拒否急増アラート
- SCC：Premium の有効化は組織側の操作（Terraform 対象外）。ここでは High/Critical の検出を Pub/Sub に流し、未処理滞留を監視（No.7）
- 運用管理 VM：複数ゾーンの MIG で自動修復。外部 IP なし、OS Login、Shielded VM（No.5）
- ログの長期保管・BigQuery 横断検索は 1-org の組織シンクで実施（No.8）
