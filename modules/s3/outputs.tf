output "s3_bucket_id" {
  description = "Private upload S3 bucket ID"
  value       = aws_s3_bucket.s3.id
}

output "s3_bucket_name" {
  description = "Private upload S3 bucket name"
  value       = aws_s3_bucket.s3.bucket
}

output "s3_bucket_arn" {
  description = "Private upload S3 bucket ARN"
  value       = aws_s3_bucket.s3.arn
}

output "s3_object_prefix" {
  description = "S3 object prefix managed by the backend"
  value       = local.normalized_object_prefix
}

output "backend_s3_role_arn" {
  description = "IRSA role ARN used by the backend ServiceAccount"
  value       = aws_iam_role.backend_s3.arn
}

output "backend_service_account_name" {
  description = "Kubernetes ServiceAccount used by the backend Deployment"
  value       = kubernetes_service_account_v1.backend.metadata[0].name
}

output "ai_s3_role_arn" {
  description = "IRSA role ARN used by the AI ServiceAccount"
  value       = aws_iam_role.ai_s3.arn
}

output "ai_service_account_name" {
  description = "Kubernetes ServiceAccount used by the AI Deployment"
  value       = kubernetes_service_account_v1.ai.metadata[0].name
}

