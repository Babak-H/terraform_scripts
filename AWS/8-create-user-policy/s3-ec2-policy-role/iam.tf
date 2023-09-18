# create the policy that will be attached to a role
resource "aws_iam_policy" "s3-read-policy" {
  name = "s3-read-policy"
  policy = "${file("s3-policy.json")}"
}

# create the role
# the policy inside it allows the role to assume extra policies related to ec2 instance
resource "aws_iam_role" "s3-read-role" {
  name = "s3-read-role"
  assume_role_policy = "${file("s3-assume-policy.json")}"
}

# attach role to plicy (role binding)
resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.s3-read-role.name
  policy_arn = aws_iam_policy.s3-read-policy.arn
}

# an Iam instance profile passes an IAM role to an instance
resource "aws_iam_instance_profile" "main" {
  name = "ec2-read-s3"
  role = aws_iam_role.s3-read-role.name
}
