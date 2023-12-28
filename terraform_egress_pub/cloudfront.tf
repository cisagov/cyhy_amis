locals {
  # bucket origin id
  s3_origin_id = "S3-${aws_s3_bucket.rules_bucket.id}"
}

data "aws_acm_certificate" "rules_cert" {
  domain      = var.distribution_domain
  most_recent = true
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
}

# An S3 bucket where artifacts for the Lambda@Edge can be stored
resource "aws_s3_bucket" "lambda_artifact_bucket" {
  bucket_prefix = "cyhy-egress-lambda-at-edge"
}

# Ensure the S3 bucket is encrypted
resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_artifact_bucket" {
  bucket = aws_s3_bucket.lambda_artifact_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# This blocks ANY public access to the bucket or the objects it
# contains, even if misconfigured to allow public access.
resource "aws_s3_bucket_public_access_block" "lambda_artifact_bucket" {
  bucket = aws_s3_bucket.lambda_artifact_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Any objects placed into this bucket should be owned by the bucket
# owner. This ensures that even if objects are added by a different
# account, the bucket-owning account retains full control over the
# objects stored in this bucket.
resource "aws_s3_bucket_ownership_controls" "lambda_artifact_bucket" {
  bucket = aws_s3_bucket.lambda_artifact_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "lambda_artifact_bucket" {
  bucket = aws_s3_bucket.lambda_artifact_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# A Lambda@Edge for injecting security headers
module "security_header_lambda" {
  source  = "transcend-io/lambda-at-edge/aws"
  version = "0.5.0"

  description            = "Adds HSTS and other security headers to the response"
  lambda_code_source_dir = "${path.root}/add_security_headers"
  name                   = "add_security_headers"
  runtime                = "nodejs18.x"
  s3_artifact_bucket     = aws_s3_bucket.lambda_artifact_bucket.id
  tags                   = { "Application" = "Egress Publish" }
}

resource "aws_cloudfront_origin_access_control" "rules_s3_distribution" {
  description = var.distribution_oac_description
  name        = var.distribution_oac_name

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "rules_s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.rules_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.rules_s3_distribution.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terraform egress site"
  default_root_object = var.root_object

  aliases = [var.distribution_domain]

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    lambda_function_association {
      # Inject security headers via Lambda@Edge
      event_type   = "origin-response"
      include_body = false
      lambda_arn   = module.security_header_lambda.arn
    }
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    min_ttl                = 0
    default_ttl            = 30
    max_ttl                = 30
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "PR", "VI", "AS", "GU", "MP"]
    }
  }

  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 30
    response_code         = 200
    response_page_path    = "/${var.root_object}"
  }

  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 30
    response_code         = 200
    response_page_path    = "/${var.root_object}"
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.rules_cert.arn
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method       = "sni-only"
  }

  tags = { "Application" = "Egress Publish" }
}
