# create a new user in the IAM
resource "aws_iam_user" "demo_user" {
  name = "Linux"
}

# access key creation for the user
resource "aws_iam_access_key" "key" {
  user = aws_iam_user.demo_user.name
}

# Secret access key
output "secret_key" {
  value     = aws_iam_access_key.key.secret
  sensitive = true
}

# Access key ID
output "access_key" {
  value = aws_iam_access_key.key.id
}

# create a policy and attach it to the user
resource "aws_iam_user_policy" "iam" {
  name = "demo_policy"
  user = aws_iam_user.demo_user.name

  policy = jsonencode({
    Version: "2012-10-17"
    Statement: [
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        }
    ]
  })
}