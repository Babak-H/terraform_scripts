output "bucket_domain_name" {
  value = aws_s3_bucket.babak2023s3bucketjan.bucket_regional_domain_name
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.dev-cloudfront1.domain_name
}
