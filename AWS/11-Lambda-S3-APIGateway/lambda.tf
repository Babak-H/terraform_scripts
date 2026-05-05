# create an execution role that Lambda can assume
resource "aws_iam_role" "hello_lambda_exec" {
  name = "hello-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# attach the AWS-managed policy that allows Lambda to write CloudWatch Logs
resource "aws_iam_role_policy_attachment" "hello_lambda_policy" {
  role       = aws_iam_role.hello_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# create the Lambda function
resource "aws_lambda_function" "hello" {
  depends_on = [
    aws_iam_role_policy_attachment.hello_lambda_policy,
    aws_cloudwatch_log_group.hello_logs
  ]

  function_name = "my-lambda-1"

  # point to the s3 bucket and zip archive (key)
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.hello_lambda.id

  runtime = "nodejs22.x"
  handler = "function.handler"

  # redeploy when the local zip file changes
  # if you edit the code, it will change the hash and force it to be re-deployed
  source_code_hash = filebase64sha256("${path.module}/function-lambda.zip")

  # attach the execution role
  role = aws_iam_role.hello_lambda_exec.arn
}

# create a CloudWatch log group for the Lambda function, keep the logs for 14 days
resource "aws_cloudwatch_log_group" "hello_logs" {
  name              = "/aws/lambda/my-lambda-1"
  retention_in_days = 14
}



