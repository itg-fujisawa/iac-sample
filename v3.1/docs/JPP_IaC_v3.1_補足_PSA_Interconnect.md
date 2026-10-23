# 補足資料：Private Service Access と Cloud Router＋Partner Interconnect

- 対象：次期J-PlatPat Google Cloud IaC v3.1（3-network）
- 関連図：JPP_IaC_v3.1_アーキテクチャ構成図（VPC 層）
- 位置づけ：構成図中の以下2要素の解説

| 構成図の表記 | IaC の定義箇所 |
|---|---|
| Private Service Access（PSA）10.30.128.0/17 | `3-network/main.tf`（`google_compute_global_address.psa`、`google_service_networking_connection.psa`） |
| Cloud Router＋Partner Interconnect ×2 | `3-network/interconnect.tf`（`google_compute_router.ic`、`google_compute_interconnect_attachment.partner`） |

どちらも、インターネットを通らずに通信するための仕組みです。

- **PSA**：Google Cloud 内のマネージドサービスとアプリを内部アドレスでつなぐ
- **Cloud Router＋Partner Interconnect**：Google Cloud と特許庁などの外部拠点を専用線でつなぐ

---

## 1. Private Service Access（PSA）10.30.128.0/17

### 1.1 何をしているか

Cloud SQL・Memorystore・Filestore は、利用者の VPC の中ではなく、Google が管理する別のネットワークで動いています。
PSA は、そのネットワークと利用者の VPC を VPC ピアリングでつなぎ、**プライベート IP だけで接続できる** ようにする仕組みです。

```
Cloud Run（app サブネット 10.30.0.0/22）
   │ Direct VPC egress（宛先がプライベートアドレスの通信だけ VPC へ）
   ▼
jpp-prod-vpc ══ VPC ピアリング（PSA）══ Google 管理ネットワーク
                                        ├ Cloud SQL       （例 10.30.128.x）
                                        ├ Memorystore     （例 10.30.129.x）
                                        └ Filestore       （例 10.30.130.x）
```

### 1.2 各項目の意味

| 項目 | 内容 |
|---|---|
| 10.30.128.0/17 | Google 管理側に貸し出すアドレス範囲（約32,000個）。各サービスはインスタンス作成のたびに、この中から小さな範囲を切り出して使う |
| 3サービスで共用 | VPC ごとに1つの範囲を、Cloud SQL・Memorystore・Filestore で共有する。サービスごとに用意する必要はない |
| 公開 IP なし | Cloud SQL は公開 IP を無効化（`ipv4_enabled = false`）。組織ポリシー（`sql.restrictPublicIp`）でも禁止しているため、インターネットからは到達できない |
| Cloud Run からの到達 | `PRIVATE_RANGES_ONLY` はプライベートアドレス宛ての通信だけを VPC に流す設定。10.30.128.0/17 はプライベートアドレスのため、DB 宛ての通信は VPC 経由になる |

### 1.3 IaC での定義（抜粋）

```hcl
resource "google_compute_global_address" "psa" {
  name          = "${local.name}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.psa_address        # prod: 10.30.128.0
  prefix_length = var.psa_prefix_length  # 17
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]
  deletion_policy         = "ABANDON"
}
```

環境別のサンプル値（`environments/{env}/3-network.tfvars`）：

| 環境 | psa_address | 範囲 |
|---|---|---|
| dev | 10.10.128.0 | 10.10.128.0/17 |
| stg | 10.20.128.0 | 10.20.128.0/17 |
| prod | 10.30.128.0 | 10.30.128.0/17 |

※ CIDR はサンプル値。外部接続調整表で重複がないことを確認してから確定する。

### 1.4 設計上の注意点

| # | 注意点 | 内容・対応 |
|---|---|---|
| 1 | アドレスの重複は後から直せない | 範囲は PSA 接続作成後に変えにくく、作り直しになる。特許庁・庁内ネットワークの範囲と重ならないことを、外部接続調整表で確認してから確定する |
| 2 | /17 の余裕 | 3環境とも VPC が分かれているため、それぞれに /17 を割当て。将来の DB 増設や、検証用の復元インスタンス作成分も含めて足りるかを確認する |
| 3 | オンプレミスから DB へ直接は届かない | VPC ピアリングは中継されないため、Interconnect 経由でオンプレミスから Cloud SQL へ直接接続できない（下記 1.5） |

### 1.5 オンプレミスから DB へ直接接続が必要な場合（v3.1 未実装）

アプリ経由の連携だけであれば不要です。直接接続が必要な場合は、次の2つを追加します。

1. Cloud Router で PSA の範囲をオンプレミス側へ広報する設定（カスタム経路広報）
2. PSA ピアリング側で、オンプレミスへの経路を交換する設定（`export_custom_routes`）

---

## 2. Cloud Router＋Partner Interconnect ×2

### 2.1 何をしているか

特許庁などの外部システムと Google Cloud を、インターネットを通らない専用線でつなぎます。
Partner Interconnect は、Google と直接接続している回線事業者（パートナー）の網を使う方式です。

```
特許庁 等 ─ 事業者網 ─┬─ VLAN アタッチメント #1（エッジ可用性ドメイン 1）─┐
                      └─ VLAN アタッチメント #2（エッジ可用性ドメイン 2）─┤
                                                                     Cloud Router（BGP）
                                                                          │ 経路を自動交換
                                                                     jpp-prod-vpc
```

### 2.2 構成要素

| 要素 | 役割 |
|---|---|
| Cloud Router | BGP でオンプレミスと VPC の経路を自動でやり取りする。片方の回線が切れても、経路が自動で切り替わる |
| ASN 16550 | Partner Interconnect で使う Google 側の AS 番号（固定値） |
| VLAN アタッチメント ×2 | 同じ地域内で、別々のエッジ可用性ドメイン（DOMAIN_1 と 2）に1本ずつ配置。片方の保守・障害時も通信を継続できる |
| Pairing Key | アタッチメント作成時に発行されるキー。事業者に渡すと回線が開通する（IaC の出力 `interconnect_pairing_keys` に機微情報として表示） |
| dev は対象外 | 開発環境は外部接続不可（3面分離）の方針のため、IaC のチェック（`check "dev_no_external_connection"`）で作成を禁止 |

### 2.3 IaC での定義（抜粋）

```hcl
resource "google_compute_router" "ic" {
  count   = var.interconnect_enabled ? 1 : 0
  name    = "${local.name}-ic-router"
  region  = var.region
  network = google_compute_network.main.id
  bgp {
    asn = 16550 # Partner Interconnect は 16550 固定
  }
}

resource "google_compute_interconnect_attachment" "partner" {
  for_each                 = var.interconnect_enabled ? toset(["1", "2"]) : toset([])
  name                     = "${local.name}-ic-${each.key}"
  region                   = var.region
  router                   = google_compute_router.ic[0].id
  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_${each.key}"
  mtu                      = var.interconnect_mtu
  admin_enabled            = true
}
```

| 環境 | interconnect_enabled |
|---|---|
| dev | false（外部接続不可） |
| stg | true |
| prod | true |

### 2.4 「×2」にしている理由

| 本数 | SLA（Google 公表） | 本件での扱い |
|---|---|---|
| 1本 | なし | 不可 |
| **2本（同じ都市圏・別ドメイン）** | **99.9%** | **v3.1 の構成** |
| 4本（2つの都市圏×2本） | 99.99% | 大阪にも回線を常設する必要がある。平時は大阪にサーバを置かない方針（cold DR）と合わないため、採用するかは要協議 |

### 2.5 通信を通すための条件（3つすべて必要）

| # | 条件 | 確認内容 |
|---|---|---|
| 1 | 経路 | BGP でオンプレミス側の範囲を学習していること |
| 2 | FW ポリシー | 外向き通信は既定で拒否しているため、`egress_allow_rules` に接続先・ポートを登録していること（外部接続調整表から作成） |
| 3 | Cloud Run の設定 | オンプレミス側がプライベートアドレスであれば、`PRIVATE_RANGES_ONLY` のままで届く。グローバルアドレスの場合は設定の見直しが必要 |

`egress_allow_rules` の記入例（`environments/prod/3-network.tfvars`）：

```hcl
egress_allow_rules = {
  jpo-gw = {
    priority    = 2000
    dest_ranges = ["192.0.2.0/24"]   # サンプル値
    protocol    = "tcp"
    ports       = ["443"]
    description = "特許庁 連携GW"
  }
}
```

### 2.6 構築時の注意点

| # | 注意点 | 内容 |
|---|---|---|
| 1 | 開通までに事業者側の作業が必要 | Terraform で作った直後のアタッチメントは、事業者の開通作業まで待ち状態。Preview→Deploy が成功しても、すぐには通信できない |
| 2 | 事業者のサービス種別で設定の分担が変わる | レイヤー3型：BGP 設定は事業者が実施。レイヤー2型：利用者側で BGP ピアを設定する必要があり、IaC への追加が必要 |
| 3 | パケットサイズ（MTU）を揃える | 既定は1500。事業者・特許庁側と同じ値に合わせないと、大きな通信が途中で失敗することがある |
| 4 | 費用が別途かかる | アタッチメントの時間課金とデータ転送料に加え、事業者の回線費用が発生する |

---

## 3. 確定が必要な事項

| # | 事項 | 影響する設定 | 確認先 |
|---|---|---|---|
| 1 | 各環境の PSA 範囲・サブネット CIDR | `psa_address`、`psa_prefix_length`、`subnets` | 外部接続調整表、特許庁・庁内 NW 担当 |
| 2 | 特許庁側から DB への直接接続の要否 | PSA 経路広報・`export_custom_routes`（未実装） | 情報館様、アプリ担当 |
| 3 | 回線事業者とサービス種別（レイヤー2／3） | BGP ピア設定の追加要否 | 回線事業者 |
| 4 | MTU | `interconnect_mtu` | 回線事業者、特許庁側 NW 担当 |
| 5 | 接続先・ポート・期限・窓口 | `egress_allow_rules` | 外部接続調整表 |
| 6 | SLA 99.99%（4本構成）の要否 | アタッチメント本数・大阪回線 | 情報館様（cold DR 方針との整合） |
