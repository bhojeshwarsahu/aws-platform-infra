# IAM policy + IRSA role for Karpenter, plus an instance profile for the
# nodes it launches. The controller's actual deployment (Helm release,
# NodePool/EC2NodeClass objects) is managed via GitOps -- this is only the
# AWS-side identity, same split as the LB controller and EBS CSI driver.
#
# Policy statements are translated 1:1 from the official AWS-published
# CloudFormation template (kept as separate policies matching AWS's own
# structure, for easier auditing against future upstream changes):
# https://raw.githubusercontent.com/aws/karpenter-provider-aws/main/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  ec2_arn_prefix = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}"
}

data "aws_iam_policy_document" "karpenter_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name               = "${var.name_prefix}-karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role.json
}

# Reuses the existing node role from iam.tf -- Karpenter-launched nodes
# need exactly the same baseline worker permissions as managed-node-group
# nodes, nothing more.
resource "aws_iam_instance_profile" "karpenter_node" {
  name = "${var.name_prefix}-karpenter-node-profile"
  role = aws_iam_role.eks_node.name
}

# --- NodeLifecyclePolicy: scoped EC2 instance/fleet/launch-template
# create/tag/delete, conditioned on the karpenter.sh/nodepool tag and
# kubernetes.io/cluster/<name>=owned (set by Karpenter itself at
# runtime on resources it creates) ---
resource "aws_iam_policy" "karpenter_node_lifecycle" {
  name = "${var.name_prefix}-karpenter-node-lifecycle-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScopedEC2InstanceAccessActions"
        Effect = "Allow"
        Resource = [
          "${local.ec2_arn_prefix}::image/*",
          "${local.ec2_arn_prefix}::snapshot/*",
          "${local.ec2_arn_prefix}:*:security-group/*",
          "${local.ec2_arn_prefix}:*:subnet/*",
          "${local.ec2_arn_prefix}:*:capacity-reservation/*",
          "${local.ec2_arn_prefix}:*:placement-group/*",
        ]
        Action = ["ec2:RunInstances", "ec2:CreateFleet"]
      },
      {
        Sid      = "AllowScopedEC2LaunchTemplateAccessActions"
        Effect   = "Allow"
        Resource = "${local.ec2_arn_prefix}:*:launch-template/*"
        Action   = ["ec2:RunInstances", "ec2:CreateFleet"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedEC2InstanceActionsWithTags"
        Effect = "Allow"
        Resource = [
          "${local.ec2_arn_prefix}:*:fleet/*",
          "${local.ec2_arn_prefix}:*:instance/*",
          "${local.ec2_arn_prefix}:*:volume/*",
          "${local.ec2_arn_prefix}:*:network-interface/*",
          "${local.ec2_arn_prefix}:*:launch-template/*",
          "${local.ec2_arn_prefix}:*:spot-instances-request/*",
        ]
        Action = ["ec2:RunInstances", "ec2:CreateFleet", "ec2:CreateLaunchTemplate"]
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                      = var.cluster_name
          }
          StringLike = {
            "aws:RequestTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedResourceCreationTagging"
        Effect = "Allow"
        Resource = [
          "${local.ec2_arn_prefix}:*:fleet/*",
          "${local.ec2_arn_prefix}:*:instance/*",
          "${local.ec2_arn_prefix}:*:volume/*",
          "${local.ec2_arn_prefix}:*:network-interface/*",
          "${local.ec2_arn_prefix}:*:launch-template/*",
          "${local.ec2_arn_prefix}:*:spot-instances-request/*",
        ]
        Action = "ec2:CreateTags"
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                      = var.cluster_name
            "ec2:CreateAction"                                         = ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
          }
          StringLike = {
            "aws:RequestTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedResourceTagging"
        Effect   = "Allow"
        Resource = "${local.ec2_arn_prefix}:*:instance/*"
        Action   = "ec2:CreateTags"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
          StringEqualsIfExists = {
            "aws:RequestTag/eks:eks-cluster-name" = var.cluster_name
          }
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = ["eks:eks-cluster-name", "karpenter.sh/nodeclaim", "Name"]
          }
        }
      },
      {
        Sid    = "AllowScopedDeletion"
        Effect = "Allow"
        Resource = [
          "${local.ec2_arn_prefix}:*:instance/*",
          "${local.ec2_arn_prefix}:*:launch-template/*",
        ]
        Action = ["ec2:TerminateInstances", "ec2:DeleteLaunchTemplate"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_lifecycle" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_node_lifecycle.arn
}

# --- IAMIntegrationPolicy: PassRole to launched instances, manage the
# instance profiles Karpenter creates for its EC2NodeClass objects ---
resource "aws_iam_policy" "karpenter_iam_integration" {
  name = "${var.name_prefix}-karpenter-iam-integration-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowPassingInstanceRole"
        Effect   = "Allow"
        Resource = aws_iam_role.eks_node.arn
        Action   = "iam:PassRole"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = ["ec2.amazonaws.com", "ec2.amazonaws.com.cn"]
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action   = ["iam:CreateInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                      = var.cluster_name
            "aws:RequestTag/topology.kubernetes.io/region"             = data.aws_region.current.region
          }
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action   = ["iam:TagInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.region
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"  = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                       = var.cluster_name
            "aws:RequestTag/topology.kubernetes.io/region"              = data.aws_region.current.region
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileActions"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action   = ["iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile", "iam:DeleteInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.region
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_iam_integration" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_iam_integration.arn
}

# --- EKSIntegrationPolicy: discover the cluster's API server endpoint ---
resource "aws_iam_policy" "karpenter_eks_integration" {
  name = "${var.name_prefix}-karpenter-eks-integration-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAPIServerEndpointDiscovery"
        Effect   = "Allow"
        Resource = aws_eks_cluster.main.arn
        Action   = "eks:DescribeCluster"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_eks_integration" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_eks_integration.arn
}

# --- InterruptionPolicy: read/delete messages from the Spot interruption
# queue (see karpenter_sqs.tf) ---
resource "aws_iam_policy" "karpenter_interruption" {
  name = "${var.name_prefix}-karpenter-interruption-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowInterruptionQueueActions"
        Effect   = "Allow"
        Resource = aws_sqs_queue.karpenter_interruption.arn
        Action   = ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:ReceiveMessage"]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_interruption" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_interruption.arn
}

# --- ZonalShiftPolicy: read-only, lets Karpenter respect an active ARC
# zonal shift on this cluster when making scheduling decisions ---
resource "aws_iam_policy" "karpenter_zonal_shift" {
  name = "${var.name_prefix}-karpenter-zonal-shift-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowZonalShiftStatusReadOnly"
        Effect   = "Allow"
        Resource = "*"
        Action   = ["arc-zonal-shift:GetManagedResource"]
        Condition = {
          StringEquals = {
            "arc-zonal-shift:ResourceIdentifier" = aws_eks_cluster.main.arn
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_zonal_shift" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_zonal_shift.arn
}

# --- ResourceDiscoveryPolicy: unconditioned read-only Describe/pricing/AMI
# lookups needed to evaluate scheduling options ---
resource "aws_iam_policy" "karpenter_resource_discovery" {
  name = "${var.name_prefix}-karpenter-resource-discovery-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRegionalReadActions"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "ec2:DescribeCapacityReservations",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.region
          }
        }
      },
      {
        Sid      = "AllowSSMReadActions"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}::parameter/aws/service/*"
        Action   = "ssm:GetParameter"
      },
      {
        Sid      = "AllowPricingReadActions"
        Effect   = "Allow"
        Resource = "*"
        Action   = "pricing:GetProducts"
      },
      {
        Sid      = "AllowUnscopedInstanceProfileListAction"
        Effect   = "Allow"
        Resource = "*"
        Action   = "iam:ListInstanceProfiles"
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Action   = "iam:GetInstanceProfile"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_resource_discovery" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_resource_discovery.arn
}
