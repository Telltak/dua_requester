resource "aws_apigatewayv2_api" "this" {
  name                         = "${var.service_name}-api"
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = true
}

resource "aws_apigatewayv2_stage" "main" {
  api_id = aws_apigatewayv2_api.this.id
  name   = "$default"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      protocol       = "$context.protocol"
      httpMethod     = "$context.httpMethod"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.this.name}"
  retention_in_days = 7
}

resource "aws_apigatewayv2_integration" "post_dua" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.dua_requester.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_dua" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /dua"
  target    = "integrations/${aws_apigatewayv2_integration.post_dua.id}"
}

resource "aws_apigatewayv2_integration" "get_duas" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "GET"
  integration_uri        = aws_lambda_function.dua_requester.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_duas" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /duas"
  target    = "integrations/${aws_apigatewayv2_integration.get_duas.id}"
}

resource "aws_apigatewayv2_integration" "patch_dua" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "PATCH"
  integration_uri        = aws_lambda_function.dua_requester.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "patch_dua" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "PATCH /dua/{ulid}"
  target    = "integrations/${aws_apigatewayv2_integration.patch_dua.id}"
}
