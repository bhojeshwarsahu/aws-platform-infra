resource "aws_kms_key" "eks" {
  description             = "KMS key for ${var.cluster_name} Kubernetes Secrets envelope encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.name_prefix}-eks-secrets-key"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks.key_id
}
