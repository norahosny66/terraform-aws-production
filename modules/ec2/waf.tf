data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# WAF ACL
resource "aws_wafv2_web_acl" "this" {
  # checkov:skip=CKV_AWS_192: "Log4j is no longer in WAF ruleset"
  name        = "${var.tags["Environment"]}-web-acl"
  description = "Protect ALB from common attacks"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.tags["Environment"]}-web-acl"
    sampled_requests_enabled   = true
  }

  # Common rules
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }


    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb" {
  count        = var.create_alb ? 1 : 0
  resource_arn = aws_lb.this[0].arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
  depends_on = [aws_wafv2_web_acl.this]
}

# resource "aws_kms_key" "waf_logs" {
#   description             = "KMS key for WAF logs"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true
#   tags                    = var.tags
# }

# data "aws_iam_policy_document" "waf_logs_kms" {
#   statement {
#     sid    = "AllowAccountKeyAdmins"
#     effect = "Allow"

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }

#     actions   = ["kms:*"]

#     resources = [aws_kms_key.waf_logs.arn]
#   }

#   statement {
#     sid    = "AllowCloudWatchLogsUse"
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["logs.${data.aws_region.current.id}.amazonaws.com"]
#     }

#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:ReEncryptFrom",
#       "kms:ReEncryptTo",
#       "kms:GenerateDataKey",
#       "kms:DescribeKey"
#     ]

#     resources = [aws_kms_key.waf_logs.arn]
#   }
# }

# resource "aws_kms_key_policy" "waf_logs_policy" {
#   key_id = aws_kms_key.waf_logs.key_id
#   policy = data.aws_iam_policy_document.waf_logs_kms.json
# }

# # CloudWatch log group for WAF
# resource "aws_cloudwatch_log_group" "waf" {
#   name              = "/aws/waf/${var.tags["Environment"]}-web-acl"
#   retention_in_days = 365
#   kms_key_id        = aws_kms_key.waf_logs.arn
#   tags              = var.tags
# }

# # Logging configuration binding WAF to CloudWatch Logs
# resource "aws_wafv2_web_acl_logging_configuration" "this" {
#   resource_arn = aws_wafv2_web_acl.this.arn
#   log_destination_configs = [
#     aws_cloudwatch_log_group.waf.arn
#   ]
# }
