provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Authenticates the same way `aws eks update-kubeconfig` sets kubectl up to:
# a short-lived token minted via `aws eks get-token`, signed with whatever
# AWS credentials are active (local user or CI's assumed role).
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.aws_region, "--output", "json"]
  }
}
