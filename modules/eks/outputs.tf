output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "cluster_role_name" {
  value = aws_iam_role.eks_cluster.name
}

output "node_role_arn" {
  value = aws_iam_role.eks_node.arn
}

output "node_role_name" {
  value = aws_iam_role.eks_node.name
}

output "kms_key_arn" {
  value = aws_kms_key.eks.arn
}

output "kms_key_id" {
  value = aws_kms_key.eks.key_id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_arn" {
  value = aws_eks_node_group.main.arn
}

output "node_group_status" {
  value = aws_eks_node_group.main.status
}

output "ebs_csi_driver_role_arn" {
  value = aws_iam_role.ebs_csi_driver.arn
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller.arn
}
