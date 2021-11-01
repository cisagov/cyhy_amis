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
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning {
    enabled = true
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

# A Lambda@Edge for injecting security headers
module "security_header_lambda" {
  source  = "transcend-io/lambda-at-edge/aws"
  version = "0.4.0"

  description            = "Adds HSTS and other security headers to the response"
  lambda_code_source_dir = "${path.root}/add_security_headers"
  name                   = "add_security_headers"
  runtime                = "nodejs14.x"
  s3_artifact_bucket     = aws_s3_bucket.lambda_artifact_bucket.id
  tags                   = merge(var.tags, { "Application" = "Egress Publish" })
}

resource "aws_cloudfront_distribution" "rules_s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.rules_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
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

  tags = merge(var.tags, { "Application" = "Egress Publish" })
}
