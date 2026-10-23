# 障害一次対応

1. アラート内容（サービス名・5xx / レイテンシ / 外形監視）を確認
2. 直近の配備（Cloud Build 履歴・Cloud Run リビジョン）を確認し、必要なら前リビジョンへトラフィックを戻す
3. Cloud SQL / Spanner / Memorystore のメトリクスと接続数を確認
4. Cloud Armor の拒否急増なら攻撃の可能性 → ルール・閾値の一時調整は変更管理を経て実施
5. 長時間化する場合は Sorry 切替（sorry-switch.md）
