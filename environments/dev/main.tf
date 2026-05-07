provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  env      = var.env
  vpc_cidr = var.vpc_cidr

  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets

  azs_public      = var.azs_public
  azs_private_app = var.azs_private_app
  azs_private_db  = var.azs_private_db

  enable_eks_tags = true
  cluster_name    = var.cluster_name
  common_tags     = local.common_tags
}

module "bastion" {
  source = "../../modules/bastion"

  env              = var.env
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]

  instance_type           = var.bastion_instance_type
  key_name                = var.bastion_key_name
  allowed_ssh_cidr_blocks = var.bastion_allowed_ssh_cidr_blocks

  common_tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  env             = var.env
  cluster_name    = var.cluster_name
  cluster_version = var.eks_cluster_version
  vpc_id          = module.vpc.vpc_id

  cluster_subnet_ids = module.vpc.private_app_subnet_ids
  node_subnet_ids    = module.vpc.private_app_subnet_ids

  endpoint_private_access                     = var.eks_endpoint_private_access
  endpoint_public_access                      = var.eks_endpoint_public_access
  public_access_cidrs                         = var.eks_public_access_cidrs
  authentication_mode                         = var.eks_authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.eks_bootstrap_cluster_creator_admin_permissions
  eks_auto_mode_enabled                       = var.eks_auto_mode_enabled

  capacity_type   = var.eks_capacity_type
  instance_types  = var.eks_instance_types
  ami_type        = var.eks_ami_type
  disk_size       = var.eks_disk_size
  desired_size    = var.eks_desired_size
  min_size        = var.eks_min_size
  max_size        = var.eks_max_size
  max_unavailable = var.eks_max_unavailable

  admin_principals = {
    eks_user = var.eks_access_principal_arn
  }

  common_tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  env        = var.env
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_db_subnet_ids

  db_identifier          = var.db_identifier
  db_name                = var.db_name
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  major_engine_version   = var.db_major_engine_version
  instance_class         = var.db_instance_class
  parameter_group_family = var.db_parameter_group_family

  username = var.db_username
  password = var.db_password

  port = var.db_port

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  iops                  = var.db_iops
  storage_throughput    = var.db_storage_throughput
  storage_encrypted     = var.db_storage_encrypted
  kms_key_id            = var.db_kms_key_id

  publicly_accessible = false
  multi_az            = var.db_multi_az
  availability_zone   = var.db_multi_az ? null : var.db_availability_zone

  backup_retention_period  = var.db_backup_retention_period
  backup_window            = var.db_backup_window
  maintenance_window       = var.db_maintenance_window
  copy_tags_to_snapshot    = var.db_copy_tags_to_snapshot
  delete_automated_backups = var.db_delete_automated_backups

  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot

  performance_insights_enabled          = var.db_performance_insights_enabled
  performance_insights_retention_period = var.db_performance_insights_retention_period
  performance_insights_kms_key_id       = var.db_performance_insights_kms_key_id

  monitoring_interval = var.db_monitoring_interval
  monitoring_role_arn = var.db_monitoring_role_arn

  enabled_cloudwatch_logs_exports = var.db_enabled_cloudwatch_logs_exports

  auto_minor_version_upgrade  = var.db_auto_minor_version_upgrade
  allow_major_version_upgrade = var.db_allow_major_version_upgrade
  apply_immediately           = var.db_apply_immediately

  ca_cert_identifier = var.db_ca_cert_identifier
  license_model      = var.db_license_model
  character_set_name = var.db_character_set_name

  allowed_cidr_blocks = []

  allowed_security_group_ids = [
    module.bastion.security_group_id,
    module.eks.node_security_group_id
  ]

  parameters          = var.db_parameters
  create_option_group = var.db_create_option_group
  options             = var.db_options

  common_tags = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_names        = var.ecr_repository_names
  image_tag_mutability    = var.ecr_image_tag_mutability
  scan_on_push            = var.ecr_scan_on_push
  force_delete            = var.ecr_force_delete
  encryption_type         = var.ecr_encryption_type
  kms_key_arn             = var.ecr_kms_key_arn
  create_lifecycle_policy = var.ecr_create_lifecycle_policy
  lifecycle_policy        = var.ecr_lifecycle_policy

  common_tags = local.common_tags
}

module "iam_autoscaler" {
  source = "../../modules/iam"

  oidc_issuer_url = module.eks.cluster_oidc_issuer
}

module "s3" {
  source = "../../modules/s3"

  bucket_name     = var.bucket_name
  s3_uploader_arn = var.s3_uploader_arn
}
