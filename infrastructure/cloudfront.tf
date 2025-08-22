data "aws_acm_certificate" "virginia" {
  provider = aws.virginia
  domain   = "*.telltak.space"
  statuses = ["ISSUED"]
  types    = ["AMAZON_ISSUED"]
}

resource "aws_cloudfront_distribution" "this" {
  aliases = ["dua.telltak.space"]
  enabled = true
  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }

  }
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cache_policy_id        = "b2884449-e4de-46a7-ac36-70bc7f1ddd6d" // NOTE: CachingOptimizedForUncompressedObjects
    target_origin_id       = "static_content"
    cached_methods         = ["GET", "HEAD"]
    compress               = true
  }

  ordered_cache_behavior { // NOTE: Disable caching for apigateway content
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" // NOTE: CachingDisabled
    target_origin_id       = "api_gateway"
    viewer_protocol_policy = "redirect-to-https"
    path_pattern           = "/api/*"
  }

  viewer_certificate {
    acm_certificate_arn            = data.aws_acm_certificate.virginia.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  origin {
    domain_name = "${aws_apigatewayv2_api.this.id}.execute-api.eu-west-1.amazonaws.com"
    origin_id   = "api_gateway"
    custom_origin_config {
      origin_ssl_protocols   = ["TLSv1.2"]
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
    }
  }

  origin {
    domain_name              = aws_s3_bucket.static_content.bucket_regional_domain_name
    origin_id                = "static_content"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  } // TODO: Add S3 origin
  # custom_error_response {} // TODO: Do I need this?

  default_root_object = "index.html"
  is_ipv6_enabled     = true        // NOTE: AFAICT there's no negative to this
  http_version        = "http2and3" // NOTE: There's no negative to this, but possible increase for users (not really in this case but still)
  price_class         = "PriceClass_100"
  # logging_config {} // TODO: Update this
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.service_name}-static-content"
  origin_access_control_origin_type = "s3"
  signing_protocol                  = "sigv4"
  signing_behavior                  = "always"
}
