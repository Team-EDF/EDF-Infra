variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS security group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "DB subnet IDs for DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS subnet_ids must contain at least two subnet IDs in different AZs."
  }
}

variable "db_identifier" {
  description = "Logical DB identifier suffix"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = null
}

variable "engine" {
  description = "RDS engine name"
  type        = string
}

variable "engine_version" {
  description = "RDS engine version"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "parameter_group_family" {
  description = "Parameter group family, e.g. postgres16, mysql8.0"
  type        = string
}

variable "major_engine_version" {
  description = "Major engine version for option group, e.g. 8.0"
  type        = string
  default     = null
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "password" {
  description = "Master password when manage_master_user_password is false"
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.password != null && length(var.password) >= 8
    error_message = "password must be at least 8 characters long."
  }
}

variable "manage_master_user_password" {
  description = "Let AWS manage master password in Secrets Manager"
  type        = bool
  default     = false
}

variable "port" {
  description = "Database port. If null, engine default will be used"
  type        = number
  default     = null
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
}

variable "max_allocated_storage" {
  description = "Storage autoscaling upper limit in GB"
  type        = number
  default     = null
}

variable "storage_type" {
  description = "Storage type: gp2, gp3, io1"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Provisioned IOPS if required"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput for gp3"
  type        = number
  default     = null
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN or ID for storage encryption"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Whether DB is publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Preferred AZ when multi_az is false"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Delete automated backups immediately when DB is deleted"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on delete"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period"
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "KMS key for Performance Insights"
  type        = string
  default     = null
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. 0 disables"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for Enhanced Monitoring"
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of logs to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrades"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply modifications immediately"
  type        = bool
  default     = false
}

variable "ca_cert_identifier" {
  description = "CA certificate identifier"
  type        = string
  default     = null
}

variable "character_set_name" {
  description = "Character set name for supported engines"
  type        = string
  default     = null
}

variable "license_model" {
  description = "License model if needed"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access DB port"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access DB port"
  type        = list(string)
  default     = []
}

variable "parameters" {
  description = "DB parameter group settings"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

variable "create_option_group" {
  description = "Whether to create option group"
  type        = bool
  default     = false
}

variable "options" {
  description = "DB option group settings"
  type = list(object({
    option_name = string
    port        = optional(number)
    version     = optional(string)
    option_settings = optional(list(object({
      name  = string
      value = string
    })))
  }))
  default = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
