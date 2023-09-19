# create IAM role for the sns with access to cloudwatch
# the policy inside it mentions that the resource that assumes this role is SNS topic
resource "aws_iam_role" "sns_logs" {
  name = "sns-logs"
  
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# attach policy to this role (reads from cloud watch logs, make group,...)
# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonSNSRole.html
resource "aws_iam_role_policy_attachment" "sns_logs" {
  role = aws_iam_role.sns_logs.name
  policy_arn = "arn:aws:iam:policy/service-role/AmazonSNSRole"
}

# create SNS topic to receive notifications from CloudWatch
resource "aws_sns_topic" "alarms" {
    name = "alarms"
    
    # only for testing! in reality set it to near 0, this is for when we get logs that everything is ok but we still send it to lambda func
    lambda_success_feedback_sample_rate = 100
    
    # the role that SNS needs to access cloudwatch and send the alarms to lambda function that subscribes to the alarm
    lambda_failure_feedback_role_arn = aws_iam_role.sns_logs.arn
    lambda_success_feedback_role_arn = aws_iam_role.sns_logs.arn
}