locals {
  s3_origin_id = "S3-s3-cdn.rules.ncats.cyber.dhs.gov" #TODO get this from bucket resource
}

resource "aws_cloudfront_distribution" "rules_s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.rules_bucket.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}" #TODO

    # s3_origin_config {
    #   origin_access_identity = ""
    # }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = "all.txt"

  aliases = ["rules.ncats.cyber.dhs.gov"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
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
    error_code = 403
    error_caching_min_ttl = 30
    response_code = 200
    response_page_path = "/all.txt"
  }

  custom_error_response {
    error_code = 404
    error_caching_min_ttl = 30
    response_code = 200
    response_page_path = "/all.txt"
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:344440683180:certificate/5ca9f52c-5c2c-4759-ad41-be9e4a662c61" #TODO
    minimum_protocol_version = "TLSv1_2016"
    ssl_support_method = "sni-only"
  }
}
