resource "aws_cloudfront_distribution" "dev-cloudfront1" {
  depends_on = [aws_s3_object.Object1]
  origin {
    domain_name = aws_s3_bucket.babak2023s3bucketjan.bucket_regional_domain_name
    origin_id = local.s3_origin_id
  }
  enabled = true
  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  # allow caching and CDN in all regions
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
    type = "ssh"
    user = var.instance_user
    private_key = tls_private_key.Web-key.private_key_pem
    host = aws_instance.Web.public_ip
  }

  provisioner "remote-exec" {
        inline = [
            "sudo su << EOF",
                    "echo \"<img src='http://${aws_cloudfront_distribution.dev-cloudfront1.domain_name}/${aws_s3_object.Object1.key}' width='300' height='380'>\" >>/var/www/html/index.html",
                    "echo \"</body>\" >>/var/www/html/index.html",
                    "echo \"</html>\" >>/var/www/html/index.html",
                    "EOF",    
        ]
  }
}