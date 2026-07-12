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

  kubernetes_version   = local.kubernetes_version
  public_subnet_ids    = values(module.network.public_subnet_ids)
  private_subnet_ids   = values(module.network.private_subnet_ids)
  public_access_cidrs  = var.eks_public_access_cidrs
  admin_principal_arns = var.eks_admin_principal_arns

  node_instance_types = local.node_instance_types
  node_capacity_type  = local.node_capacity_type
  node_min_size       = local.node_min_size
  node_max_size       = local.node_max_size
  node_desired_size   = local.node_desired_size
}

module "rds" {
  source = "../../modules/rds"

  name_prefix = local.name_prefix

  vpc_id                    = module.network.vpc_id
  database_subnet_ids       = values(module.network.database_subnet_ids)
  allowed_security_group_id = module.eks.cluster_security_group_id

  engine_version    = local.rds_engine_version
  instance_class    = local.rds_instance_class
  allocated_storage = local.rds_allocated_storage
  db_name           = local.rds_db_name
  master_username   = local.rds_master_username
}
