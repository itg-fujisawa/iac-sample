# 3-network：VPC・用途別サブネット・FW ポリシー・閉域接続

- 用途別サブネット（`subnets` map）と PSA（SQL / Memorystore / Filestore で共用）
- ネットワーク FW ポリシー：既定で外向き通信を拒否し、「外部接続調整表」の許可ルールだけを開ける（`egress_allow_rules`）
- Partner Interconnect（`interconnect_enabled`）：dev では check により禁止
- `dr_mode=warm` のときだけ大阪サブネットを作成。既定の `cold` では作成しない（No.1）

Pairing Key は出力 `interconnect_pairing_keys`（機微情報）をパートナー事業者へ連携します。
