# Generate a UNIQUE bucket name (S3 buckets are global)
BUCKET_NAME="tfstate-$(openssl rand -hex 8)"
echo "Creating S3 bucket: $BUCKET_NAME"

# Create S3 bucket for Terraform state
aws s3api create-bucket --bucket "$BUCKET_NAME" --region us-east-1 
  
# Enable versioning (critical for disaster recovery)
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1