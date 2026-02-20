# Get current AWS account ID dynamically
data "aws_caller_identity" "current" {}

# S3 bucket for Terraform remote state
resource "aws_s3_bucket" "terraform_state" {
  count  = var.manage_backend_resources ? 1 : 0
  bucket = "ami-healer-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Bucket"
    Description = "Stores Terraform remote state for ami-healer project"
  }
}

# Enable versioning on the state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.manage_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption on the state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.manage_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.manage_backend_resources ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets  = true
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  count        = var.manage_backend_resources ? 1 : 0
  name         = "ami-healer-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Description = "Manages Terraform state locks for ami-healer project"
  }
}
