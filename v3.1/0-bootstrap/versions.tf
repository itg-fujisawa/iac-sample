# 0-bootstrap はローカルから組織管理者が1回だけ実行する（Infrastructure Manager の土台を作るため）
terraform {
  required_version = "= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 6.50.0"
    }
  }
  # 初回はローカル State で作成後、backend.tf.example を backend.tf にして `terraform init -migrate-state`
}
provider "google" {
  region = var.region
}
