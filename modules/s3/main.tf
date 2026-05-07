resource "aws_s3_bucket" "s3" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pab" {
  bucket = aws_s3_bucket.s3.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowOnlySpecificUserListBucket"
        Effect = "Allow"
        Principal = {
          AWS = var.s3_uploader_arn
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.s3.arn
      },
      {
        Sid    = "AllowOnlySpecificUserUploadDelete"
        Effect = "Allow"
        Principal = {
          AWS = var.s3_uploader_arn
        }
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.s3.arn}/*"
      },
      {
        Sid       = "AllowPublicReadObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.s3.arn}/*"
      }
    ]
    }
  )
}
