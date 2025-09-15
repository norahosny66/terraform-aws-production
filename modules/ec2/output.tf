output "launch_template_id" {
  description = "ID of the created launch template"
  value       = aws_launch_template.this.id
}

output "iam_instance_profile_used" {
  description = "IAM instance profile actually attached to the EC2"
  value       = var.iam_instance_profile_name != null ? var.iam_instance_profile_name : aws_iam_instance_profile.this[0].name
}

output "ec2_role_name" {
  description = "IAM role name if created by module (null if external profile was used)"
  value       = var.iam_instance_profile_name == null ? aws_iam_role.ec2_role[0].name : null
}

