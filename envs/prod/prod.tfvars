aws_region   = "ap-south-1"
project_name = "skilli"
environment  = "prod"

# EKS API public endpoint access. Update this list whenever your public IP
# changes (e.g. dynamic ISP allocation) so kubectl keeps working.
eks_public_access_cidrs = ["103.208.70.36/32"]

eks_admin_principal_arns = ["arn:aws:iam::627807502978:user/sahu"]
