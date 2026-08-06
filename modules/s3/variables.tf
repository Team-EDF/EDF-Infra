variable "env" {
  description = "Environment name used in IAM resource names"
  type        = string
}

variable "bucket_name" {
  description = "Globally unique private S3 bucket name"
  type        = string
}

variable "object_prefix" {
  description = "Object prefix that the backend is allowed to manage"
  type        = string
  default     = "receipts"

  validation {
    condition     = length(trim(var.object_prefix, "/")) > 0
    error_message = "object_prefix must not be empty."
  }
}

variable "force_destroy" {
  description = "Whether Terraform may delete a non-empty bucket"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable S3 object versioning"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days before noncurrent object versions are permanently removed"
  type        = number
  default     = 30
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days before incomplete multipart uploads are removed"
  type        = number
  default     = 7
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN used by IRSA"
  type        = string
}

variable "oidc_issuer_url" {
  description = "EKS OIDC issuer URL used by IRSA"
  type        = string
}

variable "backend_kubernetes_namespace" {
  description = "Kubernetes namespace of the backend ServiceAccount"
  type        = string
  default     = "edf"
}

variable "backend_service_account_name" {
  description = "Kubernetes ServiceAccount used by the backend Deployment"
  type        = string
  default     = "backend-service-account"
}

variable "common_tags" {
  description = "Common AWS resource tags"
  type        = map(string)
  default     = {}
}
