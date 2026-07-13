variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "dbtlake"
}

data "aws_caller_identity" "current" {}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  suffix      = random_id.suffix.hex
  bucket_name = "${var.name_prefix}-${data.aws_caller_identity.current.account_id}-${local.suffix}"
}

# The lake bucket. dbt-athena writes seed data, model tables, and query staging
# results here. force_destroy so terraform destroy empties it.
resource "aws_s3_bucket" "lake" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "lake" {
  bucket                  = aws_s3_bucket.lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Expire Athena/dbt staging output so scratch does not accrue cost.
resource "aws_s3_bucket_lifecycle_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id
  rule {
    id     = "expire-staging"
    status = "Enabled"
    filter {
      prefix = "athena-staging/"
    }
    expiration {
      days = 7
    }
  }
}

# The Glue database is the schema dbt materializes bronze/silver/gold into.
resource "aws_glue_catalog_database" "lake" {
  name        = "${var.name_prefix}_${local.suffix}"
  description = "dbt-managed analytics schema (staging + marts)."
}

# Workgroup with encryption on; not enforced so dbt-athena can set per-model
# external locations for its materializations.
resource "aws_athena_workgroup" "lake" {
  name          = "${var.name_prefix}-${local.suffix}"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = false
    publish_cloudwatch_metrics_enabled = false
    result_configuration {
      output_location = "s3://${aws_s3_bucket.lake.bucket}/athena-staging/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

output "bucket" { value = aws_s3_bucket.lake.bucket }
output "glue_database" { value = aws_glue_catalog_database.lake.name }
output "athena_workgroup" { value = aws_athena_workgroup.lake.name }
output "s3_staging_dir" { value = "s3://${aws_s3_bucket.lake.bucket}/athena-staging/" }
output "aws_region" { value = var.aws_region }
