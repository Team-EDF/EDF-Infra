variable "env" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name suffix"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID for EKS"
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Subnet IDs for EKS cluster"
  type        = list(string)

  validation {
    condition     = length(var.cluster_subnet_ids) >= 2
    error_message = "cluster_subnet_ids must contain at least two subnet IDs."
  }
}

variable "node_subnet_ids" {
  description = "Subnet IDs for EKS managed node group"
  type        = list(string)

  validation {
    condition     = length(var.node_subnet_ids) >= 2
    error_message = "node_subnet_ids must contain at least two subnet IDs."
  }
}

variable "endpoint_private_access" {
  description = "Enable private access to EKS endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to EKS endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "Allowed CIDRs for public access to EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "capacity_type" {
  description = "Node group capacity type"
  type        = string
  default     = "ON_DEMAND"
}

variable "instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "AMI type for EKS node group"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "disk_size" {
  description = "Disk size for node group"
  type        = number
  default     = 20
}

variable "desired_size" {
  description = "Desired node count"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum node count"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum node count"
  type        = number
  default     = 3
}

variable "max_unavailable" {
  description = "Maximum unavailable nodes during update"
  type        = number
  default     = 1
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "authentication_mode" {
  description = "EKS cluster authentication mode"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster-admin permissions to the cluster creator"
  type        = bool
  default     = true
}

variable "eks_auto_mode_enabled" {
  description = "Enable EKS Auto Mode"
  type        = bool
  default     = false
}

variable "admin_principals" {
  description = "Map of named IAM principal ARNs to grant EKS cluster admin access via access entries"
  type        = map(string)
  default     = {}
}