terraform {
  backend "s3" {
    bucket         = "prod-tfstate-discrete-mule"  # ← REPLACE with YOUR production bucket
    key            = "vpc-example.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod-terraform-locks"
    encrypt        = true
  }
}