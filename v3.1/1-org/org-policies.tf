# 組織ポリシー（ベースライン）
locals {
  boolean_policies = [
    "compute.skipDefaultNetworkCreation",
    "iam.disableServiceAccountKeyCreation",
    "storage.uniformBucketLevelAccess",
    "storage.publicAccessPrevention",
    "sql.restrictPublicIp",
    "compute.requireOsLogin",
    "compute.disableSerialPortAccess",
    "iam.automaticIamGrantsForDefaultServiceAccounts",
  ]
}

resource "google_org_policy_policy" "boolean" {
  for_each = toset(local.boolean_policies)
  name     = "organizations/${var.org_id}/policies/${each.value}"
  parent   = "organizations/${var.org_id}"
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "vm_external_ip" {
  name   = "organizations/${var.org_id}/policies/compute.vmExternalIpAccess"
  parent = "organizations/${var.org_id}"
  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

# 国内リージョン限定（ISMAP・データ所在）
resource "google_org_policy_policy" "locations" {
  count  = var.enforce_resource_locations ? 1 : 0
  name   = "organizations/${var.org_id}/policies/gcp.resourceLocations"
  parent = "organizations/${var.org_id}"
  spec {
    rules {
      values {
        allowed_values = ["in:asia-northeast1-locations", "in:asia-northeast2-locations", "in:asia1-locations", "global"]
      }
    }
  }
}

# ドメイン制限共有（allUsers 等を禁止）
resource "google_org_policy_policy" "drs" {
  name   = "organizations/${var.org_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "organizations/${var.org_id}"
  spec {
    rules {
      values {
        allowed_values = var.drs_customer_ids
      }
    }
  }
}

# 例外：Sorry ページ用 Project のみ公開読取りを許可（No.11）
resource "google_org_policy_policy" "drs_sorry_exception" {
  name   = "projects/${google_project.common["sorry"].project_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "projects/${google_project.common["sorry"].project_id}"
  spec {
    inherit_from_parent = false
    rules {
      allow_all = "TRUE"
    }
  }
}
resource "google_org_policy_policy" "pap_sorry_exception" {
  name   = "projects/${google_project.common["sorry"].project_id}/policies/storage.publicAccessPrevention"
  parent = "projects/${google_project.common["sorry"].project_id}"
  spec {
    inherit_from_parent = false
    rules {
      enforce = "FALSE"
    }
  }
}
