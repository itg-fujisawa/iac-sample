# ci：Binary Authorization とパイプライン定義

- `ci/terraform`：Artifact Registry、ビルド用バケット、環境ごとの署名鍵（KMS）、attestor、Binary Authorization ポリシー。dev は監査のみ、stg/prod は強制（No.7）
- `ci/cloudbuild/app-promote.yaml`：stg の digest を prod Registry へコピー（digest 一致を検証）→ prod の鍵で署名 → 配備
- `ci/cloudbuild/iac-preview.yaml`：PR 時の Preview と証跡保存
- `ci/cloudbuild/iac-apply.yaml`：承認後の Deploy（prod のトリガーは「承認が必要」を有効化）
- `ci/cloudbuild/app-deploy.yaml`：ビルド → CRITICAL 脆弱性ゲート → 署名 → Cloud Run 更新

Git 接続（Cloud Build のリポジトリ接続）は環境側で認証操作が必要なため、トリガーは Console/gcloud で作成し、本 yaml を参照させます。
