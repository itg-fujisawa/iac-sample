# 大規模災害時の大阪再構築用（平時は適用しない）

提案書 項番3・15：大阪には平時サーバを置かず、被災時に IaC で代替環境を再構築して14日以内に復旧します。

1. `environments/prod/*.tfvars` をこのフォルダにコピーし、以下だけを変更します。
   - `region = "asia-northeast2"`、`zone = "asia-northeast2-a"`
   - サブネット・PSA の CIDR は東京と重複しない値（例：10.40.x.x）
   - `backup_bucket`：大阪の WORM バケット（復元元）
   - `domains`：本番ドメイン（DNS 切替は runbooks/dr-rebuild.md）
2. Deployment 名は `jpp-prod-osaka-<stage>`（東京の State と分ける）
3. 3-network → 4-data（空の DB を作成）→ 復元 → 5-app-infra → 6-observability の順に適用

詳細は `runbooks/dr-rebuild.md` を参照してください。
