# CHANGELOG

## v3.1（2026-10-15）
- `app/`：Java 21 / Spring Boot 3.5 の Cloud Run アプリを追加
  - Cloud SQL：Java Connector ＋ IAM データベース認証（パスワードなし・Private IP）
  - Spanner：全文検索 API（入力検証 400、障害時 503）と readiness 連携
  - `/healthz`（liveness）・`/readyz`（DB/Spanner）、graceful shutdown、Cloud Logging 形式の構造化ログ＋トレース相関
  - 同一イメージで Cloud Run Jobs として実行（`APP_JOB_NAME`）
- 5-app-infra：Spring 用の環境変数（profile・DB_USER・DB_POOL_MAX・Secret の数値 version）、Java 向け startup probe
- ci：Artifact Registry を 5-app-infra から移管（初回ビルドを先に行うため）、ビルド用バケット・権限、`app-promote.yaml`（stg と同一 digest で prod へ）
- `scripts/app_build.sh`：初回ビルド・署名と tfvars への digest 書込み

## v3（2026-10-15）
- 構成を「層＝番号、環境＝ディレクトリ」に再編（0-bootstrap〜6-observability、ci、environments/{dev,stg,prod}）
- 2章PDFとのギャップ No.1〜12 を反映（GAP-TRACE.md）
- 組織・フォルダ・共通 Project（audit / backup / sorry）を 1-org で IaC 化
- イメージ更新をアプリ CD に一本化し、Terraform は Cloud Run の「枠」のみ管理
- DR を cold（バックアップ＋IaC 再構築）既定に変更。warm は提案外オプション（network / data のみ実装）

## v2
- Infrastructure Manager 版 01〜09（patent-infra-manager）
