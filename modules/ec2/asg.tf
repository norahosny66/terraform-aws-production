resource "aws_autoscaling_group" "this" {
  name                 = "${var.tags["Environment"]}-asg"
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.subnet_ids

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # If ALB created, attach the target group; else keep empty
  target_group_arns    = var.create_alb ? [aws_lb_target_group.this[0].arn] : []

  health_check_type           = var.create_alb ? "ELB" : "EC2"
  health_check_grace_period   = 300
  force_delete                = false

  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.tags["Environment"]}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value       = 50.0
    disable_scale_in   = false
  }
}
