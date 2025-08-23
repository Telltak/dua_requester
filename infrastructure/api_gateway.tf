resource "aws_apigatewayv2_deployment" "this" {
  api_id = aws_apigatewayv2_api.this.id
  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.post_dua),
      jsonencode(aws_apigatewayv2_route.post_dua),
      jsonencode(aws_apigatewayv2_integration.get_duas),
      jsonencode(aws_apigatewayv2_route.get_duas),
      jsonencode(aws_apigatewayv2_integration.get_dua_count),
      jsonencode(aws_apigatewayv2_route.get_dua_count),
      jsonencode(aws_apigatewayv2_integration.patch_dua),
      jsonencode(aws_apigatewayv2_route.patch_dua)
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_api" "this" {
  name                         = "${var.service_name}-api"
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = false
}

data "aws_acm_certificate" "this" {
  domain   = "*.telltak.space"
  statuses = ["ISSUED"]
}

resource "aws_apigatewayv2_domain_name" "this" {
  domain_name = "dua.telltak.space"

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.this.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

data "aws_route53_zone" "this" {
  name         = "telltak.space"
  private_zone = false
}

resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this.id
  stage       = aws_apigatewayv2_stage.main.id
}

resource "aws_route53_record" "this" {
  name    = aws_apigatewayv2_domain_name.this.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
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

locals {
  api_prefix = "/api"
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
  route_key = "POST ${local.api_prefix}/dua"
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
  route_key = "GET ${local.api_prefix}/duas"
  target    = "integrations/${aws_apigatewayv2_integration.get_duas.id}"
}

resource "aws_apigatewayv2_integration" "get_dua_count" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "GET"
  integration_uri        = aws_lambda_function.dua_requester.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_dua_count" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET ${local.api_prefix}/duas/count"
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
  route_key = "PATCH ${local.api_prefix}/dua/{ulid}"
  target    = "integrations/${aws_apigatewayv2_integration.patch_dua.id}"
}
