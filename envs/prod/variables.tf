variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the EKS public API endpoint. Update as needed (e.g. when a dynamic IP changes)."
  type        = list(string)
}

variable "eks_admin_principal_arns" {
  description = "IAM principal ARNs granted EKS cluster-admin access via access entries"
  type        = list(string)
}

variable "eks_viewer_principal_arns" {
  description = "IAM principal ARNs granted read-only EKS access via access entries"
  type        = list(string)
  default     = []
}
