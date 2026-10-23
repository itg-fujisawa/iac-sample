# 5-app-infra：Cloud Run・LB・Cloud Armor・CDN・Sorry

- **Cloud Run**：`services` map で機能単位に展開（特実・意匠・商標・審判・共通 API 等）。prod は `min_instances >= 1` が必須（No.4）
- **イメージの所有者**：Terraform は「枠」のみ管理し、イメージ更新はアプリ CD が担当（`ignore_changes`）
- **アプリ（app/ Spring Boot）への受け渡し**：`SPRING_PROFILES_ACTIVE`、`DB_INSTANCE`/`DB_NAME`/`DB_USER`（IAM 認証）、`DB_POOL_MAX`、`SPANNER_DATABASE`、`APP_CONFIG`（Secret 数値 version）。Jobs は `APP_JOB_NAME` でジョブモード
- **probe**：startup・liveness とも `/healthz`（最大 240 秒の起動猶予）。DB を含む判定は `/readyz`
- **Binary Authorization**：全サービス・ジョブで `use_default = true`（ポリシーは ci/terraform、No.7）
- **Cloud Armor**：OWASP 9ルール、パス単位 throttle、IP 単位 rate_based_ban、Adaptive Protection、reCAPTCHA（No.3）。stg で `waf_preview=true` で誤検知を確認し、prod は強制モード必須
- **X-Robots-Tag**：`robots_noindex_paths` に指定したサービスへ付与
- **Sorry 切替**：`maintenance_mode=true` を Preview→Deploy（No.11）。緊急時の手動切替は `runbooks/sorry-switch.md`

DNS（Cloud DNS）は既存ゾーンの棚卸し後に別途追加します（v2 `06-edge/dns-cutover.md` の手順を継承）。
