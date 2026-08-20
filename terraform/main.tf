module "vpc" {
  source             = "./modules/vpc"
  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
}

module "iam" {
  source       = "./modules/iam"
  cluster_name = var.cluster_name
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  cluster_role_arn   = module.iam.cluster_role_arn
  node_role_arn      = module.iam.node_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  environment        = var.environment
}
resource "aws_secretsmanager_secret" "rd_api_secrets" {
  name        = "rd-api-secret-${var.environment}"
  description = "Secrets for rd-api service stored in AWS Secrets Manager"
  tags = {
    Project     = "rd-task-tracker"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rd_api_secrets_version" {
  secret_id = aws_secretsmanager_secret.rd_api_secrets.id
  secret_string = jsonencode({
    SECRET_KEY  = var.secret_key
    DB_PASSWORD = var.db_password
    JWT_SECRET  = var.jwt_secret
  })
}

