# 4-data：Cloud SQL・Spanner・Memorystore・Filestore・原本・バックアップ

| 対象 | 平常時（東京） | 大規模災害（cold・既定） |
|---|---|---|
| Cloud SQL | HA（stg/prod 必須）、PITR 7日 | 自動バックアップの保管先を大阪に設定。大阪で復元 |
| Spanner | regional 東京・Enterprise、日次 backup | 日次エクスポートを大阪 WORM へ。または Cloud SQL/GCS から再生成 |
| 原本 GCS | 東京・世代管理 | Storage Transfer で大阪 WORM へ日次複製 |
| Memorystore / Filestore | Standard HA / A-24 ティア | 再構築（正本ではない） |

`dr_mode=warm`（提案外オプション）の場合のみ大阪レプリカを作成します。
Spanner の DDL は `sql/search-schema.sql`（追記型で変更すること）。indexer は fine-grained access の `indexer` ロールのみで、DDL 権限はありません。
