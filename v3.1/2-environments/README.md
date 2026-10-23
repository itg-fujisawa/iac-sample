# 2-environments：環境別 Project・API・SA・予算

環境（dev/stg/prod）ごとに1つの Infrastructure Manager Deployment として適用します。

- Project：`prj-{env}-patent`（環境フォルダ配下）
- API：Cloud Run / SQL / Spanner / Memorystore / Filestore / Batch / Model Armor / Binary Authorization ほか（No.5・7）
- SA：用途別に7種（app-runtime / app-builder / batch-job / mig-batch / indexer / backup-ops / ops-vm）
- 予算：stg/prod は `budget_amount > 0` と通知先を必須にしています（No.10）
- SCC：Premium の有効化は組織側の操作です。ここでは閲覧権限のみ付与します（No.7）

適用後、出力 `backup_writer_members` を `environments/common/1-org.tfvars` の `backup_writers` に転記し、1-org を再適用します。
