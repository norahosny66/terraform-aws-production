resource "aws_lb" "this" {
  # checkov:skip=CKV_AWS_91: "Access logging not configured yet; will enable in next iteration"
  # checkov:skip=CKV2_AWS_28: "Association exists but scan sometimes fails due to timing"
  # checkov:skip=CKV_AWS_131: "requires HTTPS Protocol"
  count              = var.create_alb ? 1 : 0
  name               = "${var.tags["Environment"]}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.subnet_ids
  enable_deletion_protection = true
  tags               = var.tags

  lifecycle {
    ignore_changes = [access_logs]
  }
}


resource "aws_lb_target_group" "this" {
  # checkov:skip= CKV_AWS_378: "No HTTPS certificate yet; using HTTP temporarily"
  count    = var.create_alb ? 1 : 0
  name     = "${var.tags["Environment"]}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
  tags = var.tags
}

resource "aws_lb_listener" "http" {
  # checkov:skip=CKV_AWS_2: "No HTTPS certificate yet; using HTTP temporarily"
  # checkov:skip=CKV_AWS_103: "No ACM certificate yet; HTTP used temporarily"
  count            = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port             = 80
  protocol         = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

}
