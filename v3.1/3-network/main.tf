resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = "${local.name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "sub" {
  for_each                 = var.subnets
  project                  = var.project_id
  name                     = "${local.name}-${each.key}"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = each.value.cidr
  description              = each.value.purpose
  private_ip_google_access = true
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# PSA：Cloud SQL / Memorystore / Filestore で共用
resource "google_compute_global_address" "psa" {
  project       = var.project_id
  name          = "${local.name}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.psa_address
  prefix_length = var.psa_prefix_length
  network       = google_compute_network.main.id
}
resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]
  deletion_policy         = "ABANDON"
}

resource "google_compute_router" "nat" {
  count   = var.nat_enabled ? 1 : 0
  project = var.project_id
  name    = "${local.name}-nat-router"
  region  = var.region
  network = google_compute_network.main.id
}
resource "google_compute_router_nat" "nat" {
  count                              = var.nat_enabled ? 1 : 0
  project                            = var.project_id
  name                               = "${local.name}-nat"
  region                             = var.region
  router                             = google_compute_router.nat[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.sub
    content {
      name                    = subnetwork.value.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# warm（提案外オプション）時のみ大阪サブネット。cold では作らない（No.1）
resource "google_compute_subnetwork" "dr" {
  count                    = var.dr_mode == "warm" ? 1 : 0
  project                  = var.project_id
  name                     = "${local.name}-app-dr"
  region                   = var.dr_region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.dr_subnet_cidr
  private_ip_google_access = true
  lifecycle {
    precondition {
      condition     = var.dr_subnet_cidr != ""
      error_message = "dr_subnet_cidr is required for warm DR."
    }
  }
}
