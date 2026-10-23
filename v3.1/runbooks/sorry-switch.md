# Sorry ページ切替

**通常**：`environments/prod/5-app-infra.tfvars` の `maintenance_mode = true` → Preview → Deploy（承認付き）

**緊急（Infrastructure Manager が使えない場合）**：
```bash
gcloud compute url-maps set-default-service jpp-prod-urlmap \
  --default-backend-bucket=jpp-prod-sorry --global --project=PROD_PROJECT
```
復旧後、tfvars を実態に合わせて Preview を実行し、差分が 0 であることを確認します。

**文言更新**：情報館様職員は `sorry_editors` グループの権限で、大阪の Sorry バケットの index.html を直接更新できます（提案書 項番51）。
