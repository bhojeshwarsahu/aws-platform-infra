module "network" {
  source = "../../modules/network"

  name_prefix  = local.name_prefix
  cluster_name = local.cluster_name

  vpc_cidr              = local.vpc_cidr
  azs                   = local.azs
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs
}

module "eks" {
  source = "../../modules/eks"

  name_prefix  = local.name_prefix
  cluster_name = local.cluster_name
}
