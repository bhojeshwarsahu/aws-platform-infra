resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Read-only Kubernetes API access -- needed by any principal running
# `terraform plan` (not just apply), since refreshing state for
# kubernetes_*/helm_* resources requires querying the cluster's own API,
# not just AWS APIs. The CI apply role doesn't need this: it already has
# implicit cluster-admin as the cluster's original creator via
# bootstrap_cluster_creator_admin_permissions.
resource "aws_eks_access_entry" "viewer" {
  for_each = toset(var.viewer_principal_arns)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
}

resource "aws_eks_access_policy_association" "viewer" {
  for_each = toset(var.viewer_principal_arns)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }
}
