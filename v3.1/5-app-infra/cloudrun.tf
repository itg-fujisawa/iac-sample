# No.4：機能単位の Cloud Run サービス（Binary Authorization 強制 No.7）
# アプリ本体：app/（Spring Boot）。Artifact Registry は ci/terraform が所有（初回ビルドを先に行うため）
locals {
  spring_profiles = join(",", compact(["cloud", var.spanner_database != "" ? "spanner" : ""]))
  # サービス・ジョブ共通の環境変数
  common_env = {
    SPRING_PROFILES_ACTIVE = local.spring_profiles
    APP_ENV                = var.environment
    GOOGLE_CLOUD_PROJECT   = var.project_id
    DB_INSTANCE            = var.sql_connection_name
    DB_NAME                = var.db_name
    DB_POOL_MAX            = tostring(var.db_pool_max)
    SPANNER_DATABASE       = var.spanner_database
    REDIS_HOST             = var.redis_host
    JAVA_TOOL_OPTIONS      = var.java_tool_options
  }
}
resource "google_cloud_run_v2_service" "svc" {
  for_each             = var.services
  project              = var.project_id
  name                 = "${local.name}-${each.key}"
  location             = var.region
  deletion_protection  = var.deletion_protection
  ingress              = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  invoker_iam_disabled = true # 【要検証】ドメイン制限共有下で allUsers を使わずに LB から呼び出す
  labels               = local.labels

  binary_authorization {
    use_default = true
  }

  template {
    service_account                  = var.service_accounts["app-runtime"]
    max_instance_request_concurrency = each.value.concurrency
    timeout                          = "60s"
    scaling {
      min_instance_count = each.value.min_instances
      max_instance_count = each.value.max_instances
    }
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = var.network
        subnetwork = var.subnets["app"]
      }
    }
    containers {
      image = each.value.image
      ports {
        container_port = 8080
      }
      resources {
        limits = {
          cpu    = each.value.cpu
          memory = each.value.memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }
      dynamic "env" {
        for_each = merge(local.common_env, {
          APP_SERVICE = each.key
          DB_USER     = trimsuffix(var.service_accounts["app-runtime"], ".gserviceaccount.com")
        })
        content {
          name  = env.key
          value = env.value
        }
      }
      dynamic "env" {
        for_each = var.app_secret_version == "" ? [] : [var.app_secret_version]
        content {
          name = "APP_CONFIG"
          value_source {
            secret_key_ref {
              secret  = var.app_secret_id
              version = env.value
            }
          }
        }
      }
      # Spring Boot の起動時間を考慮（最大 period×failure = 240 秒）
      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 3
        period_seconds        = 5
        failure_threshold     = 48
        http_get {
          path = "/healthz"
          port = 8080
        }
      }
      liveness_probe {
        timeout_seconds   = 3
        period_seconds    = 30
        failure_threshold = 3
        http_get {
          path = "/healthz"
          port = 8080
        }
      }
    }
  }

  # イメージ更新はアプリ CD（ci/cloudbuild/app-deploy.yaml）が所有。Terraform は枠のみ管理
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].revision,
      client,
      client_version,
    ]
    precondition {
      condition     = var.environment != "prod" || each.value.min_instances >= 1
      error_message = "prod は min_instances >= 1（コールドスタート回避。提案書 項番10）。"
    }
  }
}

resource "google_cloud_run_v2_job" "job" {
  for_each            = var.jobs
  project             = var.project_id
  name                = "${local.name}-${each.key}"
  location            = var.region
  deletion_protection = var.deletion_protection
  labels              = local.labels
  binary_authorization {
    use_default = true
  }
  template {
    task_count  = each.value.task_count
    parallelism = each.value.parallelism
    template {
      service_account = var.service_accounts["batch-job"]
      timeout         = each.value.timeout
      max_retries     = 1
      vpc_access {
        egress = "PRIVATE_RANGES_ONLY"
        network_interfaces {
          network    = var.network
          subnetwork = var.subnets["batch"]
        }
      }
      containers {
        image = each.value.image
        resources {
          limits = {
            cpu    = each.value.cpu
            memory = each.value.memory
          }
        }
        dynamic "env" {
          for_each = merge(local.common_env, {
            APP_SERVICE  = "job-${each.key}"
            APP_JOB_NAME = each.key
            DB_USER      = trimsuffix(var.service_accounts["batch-job"], ".gserviceaccount.com")
          })
          content {
            name  = env.key
            value = env.value
          }
        }
        dynamic "env" {
          for_each = var.app_secret_version == "" ? [] : [var.app_secret_version]
          content {
            name = "APP_CONFIG"
            value_source {
              secret_key_ref {
                secret  = var.app_secret_id
                version = env.value
              }
            }
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image, client, client_version]
  }
}

check "batch_subnet_for_jobs" {
  assert {
    condition     = length(var.jobs) == 0 || contains(keys(var.subnets), "batch")
    error_message = "Cloud Run Jobs を使う場合は 3-network に batch サブネットが必要。"
  }
}
