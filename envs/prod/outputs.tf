output "lb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller's ServiceAccount annotation"
  value       = module.eks.lb_controller_role_arn
}

output "karpenter_controller_role_arn" {
  description = "IAM role ARN for Karpenter's ServiceAccount annotation"
  value       = module.eks.karpenter_controller_role_arn
}

output "karpenter_node_instance_profile_name" {
  description = "Instance profile name for Karpenter's EC2NodeClass"
  value       = module.eks.karpenter_node_instance_profile_name
}

output "karpenter_interruption_queue_name" {
  description = "SQS queue name for Karpenter's --interruption-queue setting"
  value       = module.eks.karpenter_interruption_queue_name
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator's ServiceAccount annotation"
  value       = aws_iam_role.external_secrets.arn
}
