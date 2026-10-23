# 1-org：組織ポリシー・フォルダ・共通 Project

| 作成物 | 対応ギャップ |
|---|---|
| fld-dev / fld-stg / fld-prod（fld-mig は作らない） | 構成再編 |
| 組織ポリシー（デフォルトVPC禁止、SA鍵禁止、公開IP禁止、国内リージョン限定、ドメイン制限共有 等） | 項番17・18 |
| prj-common-audit：ロック可能なログバケット400日＋BigQuery連携＋組織シンク | No.8 |
| prj-common-backup：大阪・WORM（保持ロック）バケット、任意で Backup and DR ボールト | No.1・2 |
| prj-common-sorry：大阪の Sorry ページ、職員更新権限 | No.11 |

**2巡目の適用**：2-environments 適用後、出力 `backup_writer_members` を `backup_writers` に設定して再度 Preview/Deploy します。

**解除不可の設定**：`lock_audit_bucket` と `lock_backup_buckets` は true にすると戻せません。stg で確認してから有効化します。
