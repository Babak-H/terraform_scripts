resource "aws_iam_role" "main" {
  name = "main"
  # already existing policy(managed policy), it doesnt need policy attachment resource
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]
  assume_role_policy = "${file("${path.module}/s3-assume-policy.json")}"
}

resource "aws_iam_instance_profile" "main" {
  name = "main"
  role = aws_iam_role.main.name
}