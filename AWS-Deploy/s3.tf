# ==============================================================================
# AWS S3 Bucket: Secure, Encrypted, and 100% Cleanly Destroyable
# ==============================================================================

# Random suffix to prevent global S3 bucket name collision errors
resource "random_string" "s3_suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. Main S3 Bucket
resource "aws_s3_bucket" "app_storage" {
  bucket = "${var.project_name}-bucket-${random_string.s3_suffix.result}"

  # CRITICAL FOR CLEAN TEARDOWN
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-bucket"
    Description = "Storage bucket with force_destroy enabled for clean teardown"
  }
}

# 2. Block all Public Access
resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Default Server-Side Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "app_storage_sse" {
  bucket = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 5. Sample file uploaded via Terraform
resource "aws_s3_object" "welcome_note" {
  bucket       = aws_s3_bucket.app_storage.id
  key          = "welcome.txt"
  content      = "Welcome to ${var.project_name}! This file proves Terraform S3 provisioning works. force_destroy=true ensures this deletes cleanly on terraform destroy."
  content_type = "text/plain"
}