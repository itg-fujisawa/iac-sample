# 0-bootstrap：Infrastructure Manager の土台

組織管理者がローカルから **1回だけ** 実行します（以後の 1〜6・ci は Infrastructure Manager で管理）。

作成するもの：`fld-common`、`prj-common-iac`、実行SA（im-org / im-dev / im-stg / im-prod）、CI用SA（im-ci）、State・証跡バケット。

```bash
cd 0-bootstrap
cp ../environments/common/0-bootstrap.tfvars terraform.tfvars   # 実値を記入
terraform init && terraform plan -out=tfplan && terraform apply tfplan
cp backend.tf.example backend.tf   # bucket を output の値に置換
terraform init -migrate-state
```

完了条件：出力値を `environments/common/1-org.tfvars` と `scripts/im.env` に転記し、`terraform plan` の差分が 0 であること。
SA鍵は発行しません。prod の executor は dev/stg と別SAで、Deploy は CI 承認経由に限定します。
