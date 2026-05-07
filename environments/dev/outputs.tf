output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private DB subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "db_address" {
  description = "RDS address"
  value       = module.rds.db_address
}

output "db_port" {
  description = "RDS port"
  value       = module.rds.db_port
}

output "db_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

output "db_subnet_group_name" {
  description = "RDS DB subnet group name"
  value       = module.rds.db_subnet_group_name
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.rds_security_group_id
}

output "bastion_public_ip" {
  description = "Bastion public IP"
  value       = module.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Bastion public DNS"
  value       = module.bastion.public_dns
}

output "bastion_security_group_id" {
  description = "Bastion security group ID"
  value       = module.bastion.security_group_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "eks_node_group_name" {
  description = "EKS node group name"
  value       = module.eks.node_group_name
}

output "eks_oidc_issuer" {
  description = "EKS OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "ECR repository names"
  value       = module.ecr.repository_names
}