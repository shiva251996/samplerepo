resource "aws_s3_bucket" "loki" {
  bucket = "obs-loki-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "loki_lifecycle" {
  bucket = aws_s3_bucket.loki.id

  rule {
    id     = "loki-expire"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

data "aws_caller_identity" "current" {}
