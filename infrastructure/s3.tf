resource "aws_s3_bucket" "static_content" {
  bucket = "${var.service_name}-${data.aws_caller_identity.this.account_id}-static"
}

resource "aws_s3_bucket_policy" "static_content" {
  bucket = aws_s3_bucket.static_content.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_content.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.this.account_id}:distribution/${aws_cloudfront_distribution.this.id}"
          }
        }
      }
  ] })
}
