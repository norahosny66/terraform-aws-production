resource "aws_s3_bucket" "production_state" {
  bucket = "prod-tfstate-${random_pet.id.id}" # e.g., prod-tfstate-dog-cat

  lifecycle {
    prevent_destroy = true # 🔒 Critical: Never delete state!
  }
}

resource "aws_s3_bucket_versioning" "production_state_versioning" {
  bucket = aws_s3_bucket.production_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.production_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.production_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "production_locks" {
  name         = "prod-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "random_pet" "id" {
  length = 2
}