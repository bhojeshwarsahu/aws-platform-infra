# The cluster security group is auto-created by EKS itself (exposed via
# aws_eks_cluster.main.vpc_config[0].cluster_security_group_id), not a
# resource this module owns directly -- aws_ec2_tag lets us tag it anyway.
# Combined with the karpenter.sh/discovery tag on the private subnets
# (modules/network), this is what a future Karpenter controller will use
# to auto-discover where it's allowed to launch nodes.
resource "aws_ec2_tag" "karpenter_discovery_cluster_sg" {
  resource_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
