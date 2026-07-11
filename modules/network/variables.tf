variable "name_prefix" {
  description = "Prefix used for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used for kubernetes.io/cluster subnet tags"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets and NAT gateways across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Map of AZ to public subnet CIDR block"
  type        = map(string)
}

variable "private_subnet_cidrs" {
  description = "Map of AZ to private subnet CIDR block"
  type        = map(string)
}

variable "database_subnet_cidrs" {
  description = "Map of AZ to database subnet CIDR block"
  type        = map(string)
}
