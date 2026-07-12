output "lb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller's ServiceAccount annotation"
  value       = module.eks.lb_controller_role_arn
}
