locals {
  default_ports = {
    mysql         = 3306
    postgres      = 5432
    mariadb       = 3306
    oracle-ee     = 1521
    oracle-se2    = 1521
    sqlserver-ee  = 1433
    sqlserver-se  = 1433
    sqlserver-ex  = 1433
    sqlserver-web = 1433
  }

  db_port = var.port != null ? var.port : lookup(local.default_ports, var.engine, 3306)

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.env}-${var.db_identifier}-final-snapshot"

  create_option_group = var.create_option_group ? 1 : 0
}

resource "aws_security_group" "rds" {
  name        = "${var.env}-${var.db_identifier}-rds-sg"
  description = "Security group for RDS ${var.db_identifier}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.db_identifier}-rds-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  count = length(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = var.allowed_cidr_blocks[count.index]
  from_port         = local.db_port
  to_port           = local.db_port
  ip_protocol       = "tcp"

  description = "Allow DB access from CIDR ${var.allowed_cidr_blocks[count.index]}"
}

resource "aws_vpc_security_group_ingress_rule" "sg" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"

  description = "Allow DB access from security group ${var.allowed_security_group_ids[count.index]}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  description = "Allow all outbound traffic"
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-${var.db_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.db_identifier}-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.env}-${var.db_identifier}-parameter-group"
  family      = var.parameter_group_family
  description = "Parameter group for ${var.db_identifier}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.db_identifier}-parameter-group"
    }
  )
}

resource "aws_db_option_group" "main" {
  count = local.create_option_group

  name                     = "${var.env}-${var.db_identifier}-option-group"
  option_group_description = "Option group for ${var.db_identifier}"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  dynamic "option" {
    for_each = var.options
    content {
      option_name = option.value.option_name
      port        = lookup(option.value, "port", null)
      version     = lookup(option.value, "version", null)

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.db_identifier}-option-group"
    }
  )
}

resource "aws_db_instance" "main" {
  identifier = "${var.env}-${var.db_identifier}"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username
  password = var.password

  port = local.db_port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_throughput    = var.storage_throughput
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = var.create_option_group ? aws_db_option_group.main[0].name : null

  publicly_accessible = var.publicly_accessible
  multi_az            = var.multi_az
  availability_zone   = var.multi_az ? null : var.availability_zone

  backup_retention_period  = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  copy_tags_to_snapshot    = var.copy_tags_to_snapshot
  delete_automated_backups = var.delete_automated_backups

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  ca_cert_identifier = var.ca_cert_identifier

  character_set_name = var.character_set_name
  license_model      = var.license_model

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.db_identifier}"
    }
  )
}