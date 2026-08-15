terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "rd-task-tracker"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Stage 1: create the EKS cluster and AWS resources.
# Stage 2: update kubeconfig and then apply Kubernetes resources.
# We intentionally do not read the EKS cluster with a data source in the same
# apply because the cluster does not exist yet.
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Alternative for direct EKS auth after the cluster exists:
# data "aws_eks_cluster" "main" {
#   name = module.eks.cluster_name
# }
#
# data "aws_eks_cluster_auth" "main" {
#   name = module.eks.cluster_name
# }
#
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.main.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.main.token
# }
