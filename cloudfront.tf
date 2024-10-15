resource "aws_cloudfront_distribution" "til_viewer_app" {
  enabled = true

  origin {
    domain_name              = aws_s3_bucket.til_viewer_app.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.til_viewer_app.id
    origin_access_control_id = aws_cloudfront_origin_access_control.til_viewer_app.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.til_viewer_app.id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }
  }

  default_root_object = "index.html"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
}

resource "aws_cloudfront_origin_access_control" "til_viewer_app" {
  name                              = "til_viewer_app_origin_access_control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
