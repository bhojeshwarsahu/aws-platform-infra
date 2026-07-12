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
