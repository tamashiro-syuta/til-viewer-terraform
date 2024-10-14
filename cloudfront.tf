resource "aws_cloudfront_distribution" "til_viewer_app" {
  origin {
    domain_name = aws_s3_bucket.til_viewer_app.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.til_viewer_app.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.til_viewer_app.cloudfront_access_identity_path
    }
  }

  enabled = true

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.til_viewer_app.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "til_viewer_app" {}
