variable "region" {
  description = "AWS region"
  type        = string
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../"
  region = var.region
  name = "example-vpc"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
    Project     = "vpc-module-test"
  }
}