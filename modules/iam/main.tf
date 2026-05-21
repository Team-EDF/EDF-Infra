data "tls_certificate" "eks_oidc" {
  url = var.oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = var.oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint
  ]
}


resource "aws_iam_role" "cluster_autoscaler" {
  name = "cluster-autoscaling-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${replace(var.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_full" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "autoscaling_full" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}


#####################################################
# AWS Load Balancer Controller IRSA
#####################################################
locals {
  oidc_provider_url_without_scheme = replace(var.oidc_issuer_url, "https://", "")
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.env}-${var.cluster_name}-aws-load-balancer-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller on ${var.cluster_name}"
  policy      = file("${path.module}/aws-load-balancer-controller-policy.json")

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-aws-load-balancer-controller-policy"
    }
  )
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.env}-${var.cluster_name}-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url_without_scheme}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_url_without_scheme}:sub" = "system:serviceaccount:${var.aws_load_balancer_controller_namespace}:${var.aws_load_balancer_controller_service_account_name}"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-${var.cluster_name}-aws-load-balancer-controller-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = var.aws_load_balancer_controller_service_account_name
    namespace = var.aws_load_balancer_controller_namespace

    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }

  automount_service_account_token = true

  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}
