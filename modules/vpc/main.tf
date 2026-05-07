resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-vpc"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-igw"
    }
  )
}

#######################################
# Public Subnets
#######################################
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs_public[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-public-sn-${count.index + 1}"
    },
    var.enable_eks_tags ? {
      "kubernetes.io/role/elb"                               = "1"
      "kubernetes.io/cluster/${var.env}-${var.cluster_name}" = "shared"
    } : {}
  )
}

#######################################
# Private App Subnets
#######################################
resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnets[count.index]
  availability_zone = var.azs_private_app[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-private-app-sn-${count.index + 1}"
      Tier = "app"
    },
    var.enable_eks_tags ? {
      "kubernetes.io/role/internal-elb"                      = "1"
      "kubernetes.io/cluster/${var.env}-${var.cluster_name}" = "shared"
    } : {}
  )
}

#######################################
# Private DB Subnets
#######################################
resource "aws_subnet" "private_db" {
  count = length(var.private_db_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnets[count.index]
  availability_zone = var.azs_private_db[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-private-db-sn-${count.index + 1}"
      Tier = "db"
    }
  )
}

#######################################
# NAT Gateway
#######################################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-nat-eip"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-nat-gw"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

#######################################
# Public Route Table
#######################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#######################################
# Private App Route Table
#######################################
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-private-app-rt"
    }
  )
}

resource "aws_route_table_association" "private_app" {
  count = length(var.private_app_subnets)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

#######################################
# Private DB Route Table
#######################################
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  # local route is automatically added by AWS
  tags = merge(
    var.common_tags,
    {
      Name = "${var.env}-private-db-rt"
    }
  )
}

resource "aws_route_table_association" "private_db" {
  count = length(var.private_db_subnets)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
