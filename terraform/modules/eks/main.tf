# ─── EKS Control Plane ────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true    # Nodes talk to control plane privately
    endpoint_public_access  = true    # You can kubectl from your laptop
    public_access_cidrs     = ["0.0.0.0/0"]  # Lock this down in production
  }

  # Enable control plane logging to CloudWatch
  enabled_cluster_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  tags = { Name = var.cluster_name }
}

# ─── Managed Node Group ────────────────────────────────────────
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids   # Nodes in private subnets only

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1    # Rolling update — always keep n-1 nodes running
  }

  # Use latest EKS-optimised Amazon Linux 2 AMI
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  labels = {
    environment = var.environment
    role        = "worker"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]  # Let cluster autoscaler manage this
  }
}

# ─── EKS Add-ons ──────────────────────────────────────────────
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}