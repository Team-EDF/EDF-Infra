aws_region   = "ap-northeast-2"
project_name = "EDF-System"
env          = "edf-dev"

# -------------------------
# VPC
# -------------------------
vpc_cidr = "10.10.0.0/16"

public_subnets = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

private_app_subnets = [
  "10.10.12.0/22",
  "10.10.16.0/22"
]

private_db_subnets = [
  "10.10.24.0/24",
  "10.10.25.0/24"
]

azs_public = [
  "ap-northeast-2a",
  "ap-northeast-2c"
]

azs_private_app = [
  "ap-northeast-2a",
  "ap-northeast-2c"
]

azs_private_db = [
  "ap-northeast-2a",
  "ap-northeast-2c"
]

cluster_name = "edf-cluster"

# -------------------------
# RDS (PostGre)
# -------------------------
db_identifier             = "postgres"
db_name                   = "edf_db"
db_engine                 = "postgres"
db_engine_version         = "16.13"
db_major_engine_version   = "16"
db_instance_class         = "db.t3.micro"
db_parameter_group_family = "postgre16"

db_port = 5432

db_allocated_storage     = 20
db_max_allocated_storage = 100
db_storage_type          = "gp3"
db_iops                  = null
db_storage_throughput    = null
db_storage_encrypted     = true
db_kms_key_id            = null

db_publicly_accessible = false
db_multi_az            = false
db_availability_zone   = null

db_backup_retention_period  = 1
db_backup_window            = null
db_maintenance_window       = null
db_copy_tags_to_snapshot    = true
db_delete_automated_backups = true

db_deletion_protection = false
db_skip_final_snapshot = true

db_performance_insights_enabled          = false
db_performance_insights_retention_period = 7
db_performance_insights_kms_key_id       = null

db_monitoring_interval = 0
db_monitoring_role_arn = null

db_enabled_cloudwatch_logs_exports = []

db_auto_minor_version_upgrade  = true
db_allow_major_version_upgrade = false
db_apply_immediately           = false

db_ca_cert_identifier = null
db_license_model      = null
db_character_set_name = null

db_parameters = []

db_create_option_group = false
db_options             = []

# -------------------------
# Bastion
# -------------------------
bastion_instance_type = "t3.micro"
bastion_key_name      = "my-key-pair"

bastion_allowed_ssh_cidr_blocks = [
  "0.0.0.0/0"
]

# -------------------------
# EKS
# -------------------------
eks_cluster_version = "1.35"

eks_endpoint_private_access = true
eks_endpoint_public_access  = true

eks_public_access_cidrs = [
  "0.0.0.0/0"
]

eks_capacity_type  = "ON_DEMAND"
eks_instance_types = ["t3.small"]
eks_ami_type       = "AL2023_x86_64_STANDARD"
eks_disk_size      = 20

eks_desired_size    = 3
eks_min_size        = 3
eks_max_size        = 8
eks_max_unavailable = 1

eks_authentication_mode                         = "API_AND_CONFIG_MAP"
eks_bootstrap_cluster_creator_admin_permissions = true
eks_auto_mode_enabled                           = false

eks_access_principal_arn = "arn:aws:iam::398875891485:user/eks-user"
# -------------------------
# ECR
# -------------------------
ecr_repository_names = [
  "edf-backend",
  "edf-frontend",
  "edf-ai"
]

ecr_image_tag_mutability    = "MUTABLE"
ecr_scan_on_push            = true
ecr_force_delete            = true
ecr_encryption_type         = "AES256"
ecr_kms_key_arn             = null
ecr_create_lifecycle_policy = true

# -------------------------
# S3
# -------------------------
bucket_name     = "edf-webpage-images-398875891485"
s3_uploader_arn = "arn:aws:iam::398875891485:user/eks-user"

