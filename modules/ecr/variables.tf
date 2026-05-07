variable "repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "ECR image tag mutability. MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scan on push"
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Delete repository even if it contains images"
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "Encryption type for ECR. AES256 or KMS"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for ECR encryption when encryption_type is KMS"
  type        = string
  default     = null
}

variable "create_lifecycle_policy" {
  description = "Whether to create lifecycle policy for ECR repositories"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "Lifecycle policy JSON string for ECR repositories"
  type        = string
  default     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

variable "common_tags" {
  description = "Common tags for all ECR repositories"
  type        = map(string)
  default     = {}
}