resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  tags = merge(
    var.common_tags,
    {
      Name = each.value
    }
  )
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.create_lifecycle_policy ? aws_ecr_repository.this : {}

  repository = each.value.name
  policy     = var.lifecycle_policy
}