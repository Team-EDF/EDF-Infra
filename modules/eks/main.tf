resource "aws_iam_role" "cluster" {
  name = "${var.env}-${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-cluster-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

#####################################################
# Cluster Security Group
#####################################################
resource "aws_security_group" "cluster" {
  name        = "${var.env}-${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.node.id]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-cluster-sg"
    }
  )
}

#####################################################
# Node Security Group
#####################################################
resource "aws_security_group" "node" {
  name        = "${var.env}-${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-node-sg"
    }
  )
}

#####################################################
# SG Rules: cluster <-> node
#####################################################

# Node -> Cluster API
resource "aws_vpc_security_group_ingress_rule" "cluster_from_node_https" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.node.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow worker nodes to communicate with EKS cluster API"
}

# Cluster -> Node kubelet
resource "aws_vpc_security_group_ingress_rule" "node_from_cluster_kubelet" {
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.cluster.id
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  description                  = "Allow EKS control plane to communicate with kubelet"
}

# Node to Node all traffic
resource "aws_vpc_security_group_ingress_rule" "node_from_node_all" {
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"
  description                  = "Allow all traffic between worker nodes"
}

# Node from cluster admission webhook traffic
resource "aws_vpc_security_group_ingress_rule" "node_from_cluster_tls" {
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.cluster.id
  from_port                    = 8443
  to_port                      = 8443
  ip_protocol                  = "tcp"
  description                  = "for admission webhook"
}

# cluster from Node admission webhook traffic
resource "aws_vpc_security_group_egress_rule" "cluster_from_node_tls" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.node.id
  from_port                    = 8443
  to_port                      = 8443
  ip_protocol                  = "tcp"
  description                  = "for admission webhook"
}

#####################################################
# EKS Cluster
#####################################################
resource "aws_eks_cluster" "main" {
  name     = "${var.env}-${var.cluster_name}"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  compute_config {
    enabled = var.eks_auto_mode_enabled
  }

  vpc_config {
    subnet_ids              = var.cluster_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}"
    }
  )
}

#####################################################
# Node Group IAM Role
#####################################################
resource "aws_iam_role" "node_group" {
  name = "${var.env}-${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # iam:TagRole 권한 부족으로 임시 주석처리
  # tags = merge(
  #   var.common_tags,
  #   {
  #     Name = "${var.env}-${var.cluster_name}-node-group-role"
  #   }
  # )
}

resource "aws_iam_role_policy_attachment" "node_amazon_eks_worker_node_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_amazon_ec2_container_registry_read_only" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_amazon_eks_cni_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#####################################################
# Launch Template for Node Security Group
#####################################################
resource "aws_launch_template" "node" {
  name_prefix = "${var.env}-${var.cluster_name}-node-"

  vpc_security_group_ids = [
    aws_security_group.node.id
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      {
        Name = "${var.env}-${var.cluster_name}-node"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-node-lt"
    }
  )
}

#####################################################
# EKS Node Group
#####################################################
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.env}-${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_subnet_ids

  capacity_type  = var.capacity_type
  instance_types = var.instance_types
  ami_type       = var.ami_type

  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.node_amazon_ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.node_amazon_eks_cni_policy
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-node-group"

      # Autoscaler Discovery 태그
      "k8s.io/cluster-autoscaler/enabled"                      = "true"
      "k8s.io/cluster-autoscaler/${aws_eks_cluster.main.name}" = "owned"
    }
  )
}

#####################################################
# EKS Access Entry
#####################################################
resource "aws_eks_access_entry" "admins" {
  for_each      = var.admin_principals
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-${each.key}-access-entry"
    }
  )
}

resource "aws_eks_access_policy_association" "admins" {
  for_each      = var.admin_principals
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.admins
  ]
}
