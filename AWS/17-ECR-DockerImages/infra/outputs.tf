output "ecr_url" {
  description = "the url for ECR"
  value       = try(aws_ecr_repository.repository["backend"].repository_url, "")
}