# No.6：特許庁等との閉域接続（Partner Interconnect、2ドメイン冗長）
resource "google_compute_router" "ic" {
  count   = var.interconnect_enabled ? 1 : 0
  project = var.project_id
  name    = "${local.name}-ic-router"
  region  = var.region
  network = google_compute_network.main.id
  bgp {
    asn = 16550 # Partner Interconnect は 16550 固定
  }
}

resource "google_compute_interconnect_attachment" "partner" {
  for_each                 = var.interconnect_enabled ? toset(["1", "2"]) : toset([])
  project                  = var.project_id
  name                     = "${local.name}-ic-${each.key}"
  region                   = var.region
  router                   = google_compute_router.ic[0].id
  type                     = "PARTNER"
  edge_availability_domain = "AVAILABILITY_DOMAIN_${each.key}"
  mtu                      = var.interconnect_mtu
  admin_enabled            = true
}

check "dev_no_external_connection" {
  assert {
    condition     = var.environment != "dev" || !var.interconnect_enabled
    error_message = "開発環境は外部接続不可（3面分離）。interconnect_enabled=false にすること。"
  }
}
