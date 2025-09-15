variable "region" {
  description = "AWS region"
  type        = string
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

module "vpc" {
  source = "../../../vpc"
  name   = "example-vpc"
  region = "us-east-1"
  
}

# Call EC2 module
module "ec2" {
  source       = "../../"  # Points to EC2 module
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  s3_endpoint_id = module.vpc.s3_endpoint_id
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
    Project     = "vpc-ec2-test"
  }
  ami_id          = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type   = "t3.micro"
  create_alb      = true
  max_size        = 2
  min_size        = 1
  desired_capacity = 1
  allowed_cidr    = "0.0.0.0/0"   # For ALB access
  enable_monitoring = true
  root_volume_size  = 30
  root_volume_type  = "gp3"
  #iam_instance_profile_name = ".." # uncomment if you have existing one (Must include SSM permissions)
}