data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.env}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-bastion-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = length(var.allowed_ssh_cidr_blocks)

  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = var.allowed_ssh_cidr_blocks[count.index]
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH from ${var.allowed_ssh_cidr_blocks[count.index]}"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-bastion"
    }
  )
}