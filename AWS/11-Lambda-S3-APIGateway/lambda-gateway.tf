# connect the api-gateway and lambda function together
resource "aws_apigatewayv2_integration" "hello_lambda" {
  api_id = aws_apigatewayv2_api.main.id
  # uri to be able to invoke the lambda from api-gateway
  integration_uri = aws_lambda_function.hello.invoke_arn

  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

# allow the api-gateway to invoke the lambda function
resource "aws_lambda_permission" "api_gw" {
  statement_id = "AllowExecutionFromAPIGateway"
  action       = "lambda:InvokeFunction"
  # what function
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  # what api-gateway
  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# create get route and send it to the resource to invoke the lambda
resource "aws_apigatewayv2_route" "get_hello" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_lambda.id}"
}

# create post route and send it to the resource to invoke the lambda
resource "aws_apigatewayv2_route" "post_lambda" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = "POST /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_lambda.id}"
}

# save the url that is need to invoke the lambda as output variable
output "hello_base_url" {
  value = aws_apigatewayv2_stage.dev.invoke_url
}

