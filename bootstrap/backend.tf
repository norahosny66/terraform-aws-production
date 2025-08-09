# .terraform/backend.tf
# NEVER commit this to version control
# This is local-only configuration for init
# Production backend is defined in module configurations

terraform {
  backend "s3" {
    # Replace with YOUR actual bucket name
    bucket         = "tfstate-33c5028878cf8803" # ← CHANGE THIS
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
