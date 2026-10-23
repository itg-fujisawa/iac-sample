# Infrastructure Manager 対応版（Terraform 1.5.7 / google 6.50.0 固定）
terraform {
  required_version = "= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 6.50.0"
    }
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
  default_labels = local.labels
}
