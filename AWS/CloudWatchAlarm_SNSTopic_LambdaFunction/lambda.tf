# create the role for the lambda function (lambda function can assume this role)
resource "aws_iam_role" "send_cloudwatch_alarms_to_slack" {
  name = "send-cloudwatch-alarms-to-slack"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# 
# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AWSLambdaBasicExecutionRole.html
# similar to SNS policy, when we get the alarm from the SNS topic, we need permission for the lambda function to read it
resource "aws_iam_role_policy_attachment" "send_cloudwatch_alarms_to_slack_basic" {
  role = aws_iam_role.send_cloudwatch_alarms_to_slack.name
  policy_arn = "arn:aws:iam:aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# save the lambda function src as a zip file
data "archive_file" "send_cloudwatch_alarms_to_slack" {
  type = "zip"

  source_dir = "./functions/send_cloudwatch_alarms_to_slack"
  output_path = "./functions/send_cloudwatch_alarms_to_slack.zip"
}

# upload the zipfile to S3
resource "aws_s3_object" "send_cloudwatch_alarms_to_slack" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key = "send_cloudwatch_alarms_to_slack.zip"
  source = data.archive_file.send_cloudwatch_alarms_to_slack.output_path

  # this triggers an update, when value of the zip file changes
  etag = filemd5(data.archive_file.send_cloudwatch_alarms_to_slack.output_path)
}

# create the function itself
resource "aws_lambda_function" "send_cloudwatch_alarms_to_slack" {
  function_name = "send-cloudwatch-alarms-to-slack"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  # key name for encryption
  s3_key = aws_s3_object.send_cloudwatch_alarms_to_slack.key

  runtime = "python3.9"
  handler = "function.lambda_handler"
  # if you edit the code, it will change the hash and force it to be re-deployed
  source_code_hash = data.archive_file.send_cloudwatch_alarms_to_slack.output_base64sha256
  # the role to read the cloudwatch alarms
  role = aws_iam_role.send_cloudwatch_alarms_to_slack.arn
}

# grant sns topic permission to invoke the lambda function
resource "aws_lambda_permission" "sns_alarm" {
  # permissions
  statement_id = "AllowExecutionFromSNSAlarm"
  action = "lambda:InvokeFunction"
  # lambda func name
  function_name = aws_lambda_function.send_cloudwatch_alarms_to_slack.function_name
  # SNS topic's arn
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.alarms.arn
}

# subscribe lambda function to the SNS topic so sns can invoke it
resource "aws_sns_topic_subscription" "alarms" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol = "lambda"
  # endpoint is the resource that wants to subscribe and receive notification from SNS topic
  endpoint = aws_lambda_function.send_cloudwatch_alarms_to_slack.arn
}