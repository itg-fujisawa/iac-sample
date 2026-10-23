# app：Spring Boot アプリ（Cloud Run サービス／Jobs 共通イメージ）

Java 21 / Spring Boot 3.5。1つのイメージを機能単位の Cloud Run サービス（common-api / tokujitsu / isho / shohyo / shimpan / static）と Cloud Run Jobs に配備します。どのサービスとして動いているかは環境変数 `APP_SERVICE` で判別します。

## エンドポイント

| パス | 用途 |
|---|---|
| `/healthz` | liveness（Cloud Run の startup/liveness probe、外形監視） |
| `/readyz` | readiness：DB（＋Spanner）を含む業務可否 |
| `/api/info` | 配備確認（env / service / version） |
| `/api/search?q=&size=` | Spanner 全文検索（size は 1〜100、障害時 503） |
| `/p/**` `/d/**` `/t/**` `/s/**` | 各機能サービスの受け口（雛形） |

## Terraform（5-app-infra）が設定する環境変数

| 変数 | 内容 |
|---|---|
| `SPRING_PROFILES_ACTIVE` | `cloud`（＋Spanner 有効時 `spanner`） |
| `APP_ENV` / `APP_SERVICE` / `GOOGLE_CLOUD_PROJECT` | 環境・サービス名・Project（ログのトレース相関に使用） |
| `DB_INSTANCE` / `DB_NAME` / `DB_USER` | Cloud SQL 接続名、DB 名、IAM ユーザー（実行SA） |
| `DB_POOL_MAX` | Hikari の最大接続数 |
| `SPANNER_DATABASE` | `projects/.../databases/patent-search` |
| `APP_CONFIG` | Secret Manager（数値 version 固定。任意） |
| `APP_JOB_NAME` | Jobs のみ。設定時はジョブとして実行して終了 |

## ローカル実行

```bash
cd app
mvn spring-boot:run -Dspring-boot.run.profiles=local
curl localhost:8080/healthz
```

## ビルドと配備

- 初回（Terraform 適用前）：`scripts/app_build.sh <env>` がビルド・脆弱性ゲート・署名を行い、digest を `environments/<env>/5-app-infra.tfvars` に書き込みます
- 2回目以降：`ci/cloudbuild/app-deploy.yaml`（main マージで dev、承認で stg）
- prod：`ci/cloudbuild/app-promote.yaml` で stg と **同一 digest** をコピー・署名して配備（再ビルドしない）

## DB 権限

IAM 認証でログインできても、スキーマ・テーブル権限は付きません。DB 管理者が `GRANT` で必要最小限を付与してください（v2 の backup-restore.md の方針を継承）。
