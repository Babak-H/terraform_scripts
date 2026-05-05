#  a security feature that restricts access to Amazon S3 bucket origins so they are only accessible through specific CloudFront distributions, preventing direct public access
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.bucket_name}-oac"
  description                       = "CloudFront access to ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "dev-cloudfront1" {
  depends_on = [aws_s3_object.Object1]

  origin {
    domain_name              = aws_s3_bucket.babak2023s3bucketjan.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = local.s3_origin_id
  }

  enabled = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
  }

  # Allow CDN caching in all regions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # use default cloudfront ssl cert
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# here we want to change the address of the image on webserver to CDN address
resource "null_resource" "Write_image" {
  depends_on = [aws_cloudfront_distribution.dev-cloudfront1]

  connection {
    type        = "ssh"
    user        = var.instance_user
    private_key = tls_private_key.Web-key.private_key_pem
    host        = aws_instance.Web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh -c \"echo \\\"<img src='https://${aws_cloudfront_distribution.dev-cloudfront1.domain_name}/${aws_s3_object.Object1.key}' width='300' height='380'>\\\" >> /var/www/html/index.html\"",
      "sudo sh -c \"echo '</body>' >> /var/www/html/index.html\"",
      "sudo sh -c \"echo '</html>' >> /var/www/html/index.html\"",
    ]
  }
}
