variable "ami_id" {
  description = "AMI ID to use for instances (e.g. hardened Amazon Linux 2 or custom golden image)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH (set to null if using SSM-only)"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to attach to instances (from same VPC)"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of subnet IDs (should span multiple AZs for production)"
  type        = list(string)
}

variable "user_data" {
  description = "User data script (plain text). Module will base64-encode before sending to AWS."
  type        = string
  default     = ""
}

variable "iam_instance_profile_name" {
  description = "Name of IAM instance profile to attach (create via terraform or pass existing)"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root EBS volume type (gp3 recommended for production)"
  type        = string
  default     = "gp3"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring (CloudWatch)"
  type        = bool
  default     = true
}
variable "vpc_id" {
  description = "VPC id (required if module creates security groups or ALB)"
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "Subnets for ALB (public subnets). Leave empty if not creating ALB."
  type        = list(string)
  default     = []
}

variable "min_size" {
  description = "ASG min size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG max size"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "create_alb" {
  description = "Whether to create an ALB (true/false)"
  type        = bool
  default     = false
}

variable "allowed_cidr" {
  description = "CIDR to allow to ALB or to EC2 if no ALB (default public)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Map of tags to apply to launched instances"
  type        = map(string)
  default     = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# variable "route_table_ids" {
#   description = "List of route table IDs to associate the S3 VPC endpoint with"
#   type        = list(string)
# }

variable "s3_endpoint_id" {
  description = "The S3 VPC endpoint ID"
  type        = string
}


