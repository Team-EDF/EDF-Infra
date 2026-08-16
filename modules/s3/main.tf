locals {
  oidc_provider_url_without_scheme = replace(var.oidc_issuer_url, "https://", "")
  backend_service_account_subject  = "system:serviceaccount:${var.backend_kubernetes_namespace}:${var.backend_service_account_name}"
  ai_service_account_subject       = "system:serviceaccount:${var.ai_kubernetes_namespace}:${var.ai_service_account_name}"
  normalized_object_prefix         = trimsuffix(trimprefix(var.object_prefix, "/"), "/")
}

resource "aws_s3_bucket" "s3" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  # 버킷 이름 변경 시 새 비공개 버킷을 먼저 만든 뒤 기존 버킷을 정리한다.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.common_tags,
    {
      Name        = var.bucket_name
      DataClass   = "private-user-upload"
      AccessModel = "backend-only"
    }
  )
}

# ACL 사용을 완전히 막고 Bucket Owner가 객체 소유권을 갖게 한다.
resource "aws_s3_bucket_ownership_controls" "owner_enforced" {
  bucket = aws_s3_bucket.s3.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 사용자 영수증/명세서는 외부 공개를 전면 차단한다.
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 별도 KMS 키가 필요하지 않은 현재 단계에서는 SSE-S3(AES256)를 사용한다.
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.s3.id

  rule {
    bucket_key_enabled = false

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  count  = var.versioning_enabled ? 1 : 0
  bucket = aws_s3_bucket.s3.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 중단된 Multipart Upload와 오래된 객체 버전을 자동 정리한다.
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.s3.id

  rule {
    id     = "upload-housekeeping"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.versioning_enabled ? [1] : []

      content {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.versioning]
}

# HTTP로 S3에 접근하는 요청은 역할에 관계없이 거부한다.
resource "aws_s3_bucket_policy" "deny_insecure_transport" {
  bucket = aws_s3_bucket.s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.s3.arn,
          "${aws_s3_bucket.s3.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.private]
}

#####################################################
# Backend Pod 전용 S3 권한(IRSA)
#####################################################

resource "aws_iam_policy" "backend_s3" {
  name        = "${var.env}-backend-private-upload-s3-policy"
  description = "Least-privilege access for EDF backend to the private upload bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadBucketMetadata"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = aws_s3_bucket.s3.arn
      },
      {
        Sid      = "ListUploadPrefix"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.s3.arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              local.normalized_object_prefix,
              "${local.normalized_object_prefix}/*"
            ]
          }
        }
      },
      {
        Sid    = "ManageUploadObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.s3.arn}/${local.normalized_object_prefix}/*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-backend-private-upload-s3-policy"
    }
  )
}

resource "aws_iam_role" "backend_s3" {
  name = "${var.env}-backend-private-upload-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url_without_scheme}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_url_without_scheme}:sub" = local.backend_service_account_subject
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-backend-private-upload-s3-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "backend_s3" {
  role       = aws_iam_role.backend_s3.name
  policy_arn = aws_iam_policy.backend_s3.arn
}

# Backend Deployment가 이 ServiceAccount를 사용해야 IRSA 자격 증명이 주입된다.
resource "kubernetes_service_account_v1" "backend" {
  metadata {
    name      = var.backend_service_account_name
    namespace = var.backend_kubernetes_namespace

    labels = {
      "app.kubernetes.io/name"      = "backend"
      "app.kubernetes.io/component" = "api"
      "app.kubernetes.io/part-of"   = "edf"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.backend_s3.arn
    }
  }

  automount_service_account_token = true

  depends_on = [aws_iam_role_policy_attachment.backend_s3]
}

#####################################################
# AI Pod 전용 S3 권한(IRSA)
#####################################################

# AI는 기존 Backend와 동일한 private upload bucket의 receipts/ prefix를 사용한다.
# 별도 S3 버킷을 추가하지 않고 AI 전용 IAM Role만 분리한다.
resource "aws_iam_policy" "ai_s3" {
  name        = "${var.env}-ai-private-upload-s3-policy"
  description = "Least-privilege S3 access for EDF AI to the private upload bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.s3.arn
      },
      {
        Sid    = "ManageReceiptObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.s3.arn}/${local.normalized_object_prefix}/*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-ai-private-upload-s3-policy"
    }
  )
}

resource "aws_iam_role" "ai_s3" {
  name = "${var.env}-ai-private-upload-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url_without_scheme}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_url_without_scheme}:sub" = local.ai_service_account_subject
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-ai-private-upload-s3-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ai_s3" {
  role       = aws_iam_role.ai_s3.name
  policy_arn = aws_iam_policy.ai_s3.arn
}

# EDF-APP의 AI Deployment에서 serviceAccountName=ai-service-account를 사용해야
# 이 IRSA Role이 실제 AI Pod에 주입된다.
resource "kubernetes_service_account_v1" "ai" {
  metadata {
    name      = var.ai_service_account_name
    namespace = var.ai_kubernetes_namespace

    labels = {
      "app.kubernetes.io/name"      = "ai"
      "app.kubernetes.io/component" = "ai"
      "app.kubernetes.io/part-of"   = "edf"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ai_s3.arn
    }
  }

  automount_service_account_token = true

  depends_on = [aws_iam_role_policy_attachment.ai_s3]
}

