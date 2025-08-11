#################################
# Data Sources
#################################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#################################
# KMS Key for CloudWatch Logs
#################################
resource "aws_kms_key" "cloudwatch" {
  description         = "CMK for CloudWatch Logs for ${var.name}"
  enable_key_rotation = true

  # Secure key policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow account root full permissions
      {
        Sid = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow CloudWatch Logs service to use the key
      {
        Sid: "AllowCloudWatchLogsUseKey"
        Effect: "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, { "Name" = "${var.name}-cloudwatch-kms" })
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.name}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

#################################
# CloudWatch Log Group
#################################
resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/vpc/flow-logs/${var.name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch.arn
  tags              = merge(var.tags, { "Name" = "${var.name}-vpc-flow-logs" })
  
  lifecycle {
    prevent_destroy = true
  }
}

#################################
# IAM Role for VPC Flow Logs
#################################
resource "aws_iam_role" "vpc_flow" {
  name = "${var.name}-vpc-flow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

#################################
# Least-Privilege IAM Policy for VPC Flow Logs
#################################
resource "aws_iam_policy" "vpc_flow" {
  name        = "${var.name}-vpc-flow-policy"
  description = "Least-privilege policy for VPC Flow Logs to write to CloudWatch Logs with KMS encryption"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "WriteLogs"
        Effect: "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow.arn}:*"
      },
      {
        Sid: "UseKMS"
        Effect: "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.cloudwatch.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow" {
  role       = aws_iam_role.vpc_flow.name
  policy_arn = aws_iam_policy.vpc_flow.arn
}

#################################
# VPC Flow Logs
#################################
resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination      = aws_cloudwatch_log_group.vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.vpc_flow.arn

  tags = merge(var.tags, { "Name" = "${var.name}-vpc-flow-logs" })
}
