aws_region   = "ap-south-1"
project_name = "skilli"
environment  = "prod"

# EKS API public endpoint access is open to the internet because both
# CI (GitHub-hosted runners, dynamic non-VPC IPs) and the operator's
# dynamic IP need to reach it -- including the Kubernetes API itself for
# Terraform's kubernetes/helm provider resources, not just the AWS API.
# The real access boundary is IAM (see eks_admin_principal_arns / EKS
# access entries), not network CIDR restriction.
eks_public_access_cidrs = ["0.0.0.0/0"]

eks_admin_principal_arns = ["arn:aws:iam::627807502978:user/sahu"]

# CI's plan role needs read-only Kubernetes API access to refresh state for
# kubernetes_*/helm_* resources during `terraform plan` -- it doesn't have
# the apply role's implicit cluster-admin (that comes from being the
# cluster's original creator), and shouldn't have write access anyway.
eks_viewer_principal_arns = ["arn:aws:iam::627807502978:role/skilli-prod-github-infra-plan-role"]
