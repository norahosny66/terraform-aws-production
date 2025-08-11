
# Production-grade VPC with security and high availability

# 1. Create the VPC (the office building)
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# 2. Create PUBLIC subnets (front desk - web servers) but Make public subnets public by routing, not by auto-assign
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${count.index + 1}"
      Tier = "public"
    }
  )
}

# 3. Create PRIVATE subnets (back office - databases)
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-${count.index + 1}"
      Tier = "private"
    }
  )
}

# 4. Internet Gateway (front door to internet)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

# 5. Public Route Table (signage for public subnets)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

# 6. Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 7. NAT Gateway (secure tunnel for private servers)
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && !var.single_nat_gateway ? length(var.azs) : (var.enable_nat_gateway ? 1 : 0)

  tags = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index + 1}" })
  # checkov:skip=CKV2_AWS_19: "NAT Gateway EIPs are not attached to EC2, expected"
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway && !var.single_nat_gateway ? length(var.azs) : 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })
  
  lifecycle {
    prevent_destroy = true  # 🔒 Critical: Never delete by accident
  }
}

# 8. Private Route Table (signage for private subnets)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = merge(var.tags, { Name = "${var.name}-private-rt" })
}

# 9. Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# 10. VPC Endpoint for S3 (private, secure access)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = ["s3:*"]
        Resource = ["*"]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# 11. Default Security Group (DENY ALL posture)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

   # No ingress (default deny all inbound)
  ingress = []

  # Optional: deny all egress too (strictest)
  egress = []

  tags = merge(var.tags, { Name = "${var.name}-default-sg" })

}
