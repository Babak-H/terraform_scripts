# create api-gateway based on HTTP protocol
resource "aws_apigatewayv2_api" "main" {
  name          = "main"
  protocol_type = "HTTP"
}

# create cloudwatch log group for the api-gateway resource
resource "aws_cloudwatch_log_group" "main_api_gw" {
  name              = "/aws/api-gw/${aws_apigatewayv2_api.main.name}"
  retention_in_days = 14
}

# create environment (dev, test,...)
resource "aws_apigatewayv2_stage" "dev" {
  api_id = aws_apigatewayv2_api.main.id

  name        = "dev"
  auto_deploy = true

  # set logging settings (optional)
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.main_api_gw.arn

    format = jsonencode({
      requestId   = "$context.requestId"
      sourceIp    = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      protocol    = "$context.protocol"
      httpMethod  = "$context.httpMethod"
    })
  }
}

