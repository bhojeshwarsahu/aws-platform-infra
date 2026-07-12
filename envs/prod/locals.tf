locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  cluster_name       = "${local.name_prefix}-eks"
  kubernetes_version = "1.36"

  node_instance_types = ["t3.medium", "t3a.medium", "t2.medium"]
  node_capacity_type  = "SPOT"
  node_min_size       = 2
  node_max_size       = 4
  node_desired_size   = 2

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "aws-platform-infra"
  }

  vpc_cidr = "10.0.0.0/16"
  azs      = ["ap-south-1a", "ap-south-1b"]

  public_subnet_cidrs = {
    "ap-south-1a" = "10.0.0.0/24"
    "ap-south-1b" = "10.0.1.0/24"
  }

  private_subnet_cidrs = {
    "ap-south-1a" = "10.0.32.0/19"
    "ap-south-1b" = "10.0.64.0/19"
  }

  database_subnet_cidrs = {
    "ap-south-1a" = "10.0.2.0/24"
    "ap-south-1b" = "10.0.3.0/24"
  }
}
