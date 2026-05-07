variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) > 0
    error_message = "At least one public subnet must be provided."
  }
}

variable "private_app_subnets" {
  description = "CIDR blocks for private app subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_app_subnets) > 0
    error_message = "At least one private app subnet must be provided."
  }
}

variable "private_db_subnets" {
  description = "CIDR blocks for private db subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_db_subnets) > 0
    error_message = "At least one private db subnet must be provided."
  }
}

variable "azs_public" {
  description = "Availability zones for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.azs_public) == length(var.public_subnets)
    error_message = "azs_public and public_subnets must have the same length."
  }
}

variable "azs_private_app" {
  description = "Availability zones for private app subnets"
  type        = list(string)

  validation {
    condition     = length(var.azs_private_app) == length(var.private_app_subnets)
    error_message = "azs_private_app and private_app_subnets must have the same length."
  }
}

variable "azs_private_db" {
  description = "Availability zones for private db subnets"
  type        = list(string)

  validation {
    condition     = length(var.azs_private_db) == length(var.private_db_subnets)
    error_message = "azs_private_db and private_db_subnets must have the same length."
  }
}

variable "enable_eks_tags" {
  description = "Whether to apply EKS subnet tags"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name for subnet tagging"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
} 