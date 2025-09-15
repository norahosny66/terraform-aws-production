# create ALB SG if we are creating an ALB and no external SGs were passed
resource "aws_security_group" "alb" {
  count       = length(var.vpc_security_group_ids) == 0 && var.create_alb ? 1 : 0
  name        = "${var.tags["Environment"]}-alb-sg"
  description = "ALB SG - allow HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# create EC2 SG if no external SGs were passed
resource "aws_security_group" "ec2" {
  # checkov:skip=CKV2_AWS_5: "SG is attached dynamically to EC2, false positive"
  # checkov:skip=CKV_AWS_382: "Intended to open cidr 0.0.0.0"
  count       = length(var.vpc_security_group_ids) == 0 ? 1 : 0
  name        = "${var.tags["Environment"]}-ec2-sg"
  description = "EC2 SG - allow only ALB (or allowed_cidr if no ALB)"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = var.create_alb ? [] : [var.allowed_cidr]
    security_groups = var.create_alb ? [aws_security_group.alb[0].id] : []
    description     = var.create_alb ? "Allow from ALB" : "Allow from internet (no ALB configured)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP outbound only"
  }

  tags = var.tags
}
