resource "aws_iam_role" "ec2_role" {
  count = var.iam_instance_profile_name == null ? 1 : 0
  name  = "ec2-webserver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach SSM core policy
resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.iam_instance_profile_name == null ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count      = var.iam_instance_profile_name == null ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Optional: S3 read policy
resource "aws_iam_role_policy_attachment" "s3_read" {
  count      = var.iam_instance_profile_name == null ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Instance profile only created if no external one is provided
resource "aws_iam_instance_profile" "this" {
  count = var.iam_instance_profile_name == null ? 1 : 0
  name  = "ec2-webserver-profile"
  role  = aws_iam_role.ec2_role[0].name
}
