# IAM policy + IRSA role for External Secrets Operator, scoped to exactly
# the RDS master user secret for now (extend the resources list as more
# secrets are added). Lives at the root level rather than inside
# modules/eks or modules/rds: it needs the RDS secret's ARN (module.rds)
# and the OIDC provider (module.eks), and module.rds already depends on
# module.eks for the cluster security group -- putting this role inside
# either module would create a circular module dependency. The operator's
# actual deployment (Helm release) is managed via GitOps, same split as
# the LB controller and Karpenter.
#
# Assumes the operator's Helm release will use the service account name
# "external-secrets" in the kube-system namespace, matching every other
# controller in this cluster. If the eventual GitOps deployment uses a
# different namespace/service-account name, this trust policy must be
# updated to match, or IRSA auth will fail silently at runtime.
data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-secrets"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${local.name_prefix}-external-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json
}

data "aws_iam_policy_document" "external_secrets_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      module.rds.db_master_user_secret_arn,
    ]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "${local.name_prefix}-external-secrets-policy"
  policy = data.aws_iam_policy_document.external_secrets_permissions.json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}
