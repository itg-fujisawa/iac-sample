# No.5：運用管理 VM（複数ゾーン MIG・自動修復・外部 IP なし・OS Login）
resource "google_compute_instance_template" "ops" {
  count        = var.ops_vm_enabled ? 1 : 0
  project      = var.project_id
  name_prefix  = "${local.name}-ops-"
  machine_type = var.ops_machine_type
  region       = var.region
  labels       = local.labels
  tags         = ["ops"]
  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 50
    disk_type    = "pd-balanced"
  }
  network_interface {
    subnetwork = var.ops_subnet
  }
  service_account {
    email  = var.service_accounts["ops-vm"]
    scopes = ["cloud-platform"]
  }
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  metadata = {
    enable-oslogin = "TRUE"
  }
  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = var.ops_subnet != ""
      error_message = "ops_subnet is required when ops_vm_enabled."
    }
  }
}

resource "google_compute_health_check" "ops" {
  count   = var.ops_vm_enabled ? 1 : 0
  project = var.project_id
  name    = "${local.name}-ops-hc"
  tcp_health_check {
    port = 22
  }
}

resource "google_compute_region_instance_group_manager" "ops" {
  count              = var.ops_vm_enabled ? 1 : 0
  project            = var.project_id
  name               = "${local.name}-ops"
  region             = var.region
  base_instance_name = "${local.name}-ops"
  target_size        = var.ops_vm_count
  version {
    instance_template = google_compute_instance_template.ops[0].id
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.ops[0].id
    initial_delay_sec = 300
  }
}
