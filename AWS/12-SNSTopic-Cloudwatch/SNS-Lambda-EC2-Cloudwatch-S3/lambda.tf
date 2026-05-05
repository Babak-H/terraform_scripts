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

# Attach the AWS managed policy that lets Lambda write logs to CloudWatch Logs
# https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AWSLambdaBasicExecutionRole.html
# CreateLogGroup, CreateLogStream, PutLogEvents
resource "aws_iam_role_policy_attachment" "send_cloudwatch_alarms_to_slack_basic" {
  role       = aws_iam_role.send_cloudwatch_alarms_to_slack.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package the Lambda function source as a zip file
data "archive_file" "send_cloudwatch_alarms_to_slack" {
  type = "zip"

  source_dir  = "./functions/send_cloudwatch_alarms_to_slack"
  output_path = "./functions/send_cloudwatch_alarms_to_slack.zip"
}

# Upload the zip file to S3
resource "aws_s3_object" "send_cloudwatch_alarms_to_slack" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "send_cloudwatch_alarms_to_slack.zip"
  source = data.archive_file.send_cloudwatch_alarms_to_slack.output_path

  # Trigger an object update when the zip file changes.
  etag = filemd5(data.archive_file.send_cloudwatch_alarms_to_slack.output_path)
}

# Create the Lambda function
resource "aws_lambda_function" "send_cloudwatch_alarms_to_slack" {
  function_name = "send-cloudwatch-alarms-to-slack"

  # the bucket and the object name (key) that serves as src code of this Lambda func
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.send_cloudwatch_alarms_to_slack.key

  runtime = "python3.13"
  handler = "function.lambda_handler"

  # Redeploy the function when the packaged source changes
  source_code_hash = data.archive_file.send_cloudwatch_alarms_to_slack.output_base64sha256
  # the role to read the cloudwatch alarms,...
  role             = aws_iam_role.send_cloudwatch_alarms_to_slack.arn
}

# Manages an AWS Lambda permission. Use this resource to grant external sources (e.g., EventBridge Rules, SNS, or S3) permission to invoke Lambda functions
resource "aws_lambda_permission" "sns_alarm" {
  statement_id  = "AllowExecutionFromSNSAlarm"
  action        = "lambda:InvokeFunction"

  function_name = aws_lambda_function.send_cloudwatch_alarms_to_slack.function_name

  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarms.arn
}

# subscribe lambda function to the SNS topic so sns can invoke it
/*
Provides a resource for subscribing to SNS topics. Requires that an SNS topic exist for the subscription to attach to. This resource allows 
you to automatically place messages sent to SNS topics in SQS queues, send them as HTTP(S) POST requests to a given endpoint
*/
resource "aws_sns_topic_subscription" "alarms" {
  topic_arn = aws_sns_topic.alarms.arn
  
  protocol  = "lambda"
  endpoint  = aws_lambda_function.send_cloudwatch_alarms_to_slack.arn
}
