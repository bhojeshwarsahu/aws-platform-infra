# No IAM/IRSA needed -- metrics-server only scrapes kubelet resource
# metrics in-cluster via the Kubernetes API, never calls an AWS API.
resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "metrics-server"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}
