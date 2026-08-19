# Stage 2: Kubernetes resources.
# This file should be applied only after the EKS cluster is created and
# the kubeconfig has been updated.

resource "kubernetes_namespace" "app" {

  metadata {
    name = var.kubernetes_namespace
  }
}

resource "kubernetes_secret" "rd_api_secrets" {
  depends_on = [kubernetes_namespace.app] #depends_on = [time_sleep.wait_for_eks, kubernetes_namespace.app]

  metadata {
    name      = "rd-api-secrets-staging"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    SECRET_KEY  = var.secret_key
    DB_PASSWORD = var.db_password
    JWT_SECRET  = var.jwt_secret
  }
}
