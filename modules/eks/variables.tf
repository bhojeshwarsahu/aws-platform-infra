variable "name_prefix" {
  description = "Prefix used for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the EKS control plane ENIs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the EKS control plane ENIs"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the EKS public API endpoint"
  type        = list(string)
}

variable "admin_principal_arns" {
  description = "IAM principal ARNs granted EKS cluster-admin access via access entries"
  type        = list(string)
}
