# create a role for lambda resource, allow it to assume lambda role
resource "aws_iam_role" "hello_lambda_exec" {
  name = "hello-lambda"

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

# attach a policy to this role
resource "aws_iam_role_policy_attachment" "hello_lambda_policy" {
  role       = aws_iam_role.hello_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# create the lambda function itself 
resource "aws_lambda_function" "hello" {
  depends_on    = [data.archive_file.hello_lambda]
  function_name = "my-lambda-1"

  # point to the s3 bucket and zip archive (key)
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.hello_lambda.id

  runtime = "nodejs16.x"
  handler = "function.handler"

  # if you edit the code, it will change the hash and force it to be re-deployed
  source_code_hash = data.archive_file.hello_lambda.output_base64sha256

  # attach the role to it
  role = aws_iam_role.hello_lambda_exec.arn
}

# create cloudwatch logs (and log group) for the lambda function
# keep the logs for 14 days
resource "aws_cloudwatch_log_group" "hello-logs" {
  name              = "/aws/lambda/${aws_lambda_function.hello.function_name}"
  retention_in_days = 14
}



