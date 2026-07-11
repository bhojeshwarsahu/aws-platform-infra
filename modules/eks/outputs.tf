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
