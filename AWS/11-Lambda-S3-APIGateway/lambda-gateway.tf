# connect API Gateway and the Lambda function
resource "aws_apigatewayv2_integration" "hello_lambda" {
  api_id = aws_apigatewayv2_api.main.id

  # URI API Gateway uses to invoke Lambda
  integration_uri = aws_lambda_function.hello.invoke_arn

  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id = "AllowExecutionFromAPIGateway"
  action       = "lambda:InvokeFunction"

  # Lambda function being invoked
  function_name = aws_lambda_function.hello.function_name
  # what resource type is going to invoke the lambda
  principal     = "apigateway.amazonaws.com"

  # ARN of the exact resource
  # API Gateway execution ARN
  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# create a GET route that invokes Lambda
resource "aws_apigatewayv2_route" "get_hello" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_lambda.id}"
}

# create a POST route that invokes Lambda
resource "aws_apigatewayv2_route" "post_lambda" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = "POST /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_lambda.id}"
}
