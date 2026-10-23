locals {
  # ラベル規約：system / env / stage / managed-by / cost-center
  labels = {
    system      = "jpp"
    env         = var.environment
    stage       = "5-app-infra"
    managed-by  = "infra-manager"
    cost-center = var.cost_center
  }
  name = "jpp-${var.environment}"
}
