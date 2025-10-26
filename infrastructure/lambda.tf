resource "aws_iam_role" "lambda_exec_role" {
  name = "do-nothing-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "dua_requester" {
  function_name    = var.service_name
  runtime          = "provided.al2"
  handler          = "bootstrap"
  filename         = "${path.module}/../lambda.zip"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = filebase64sha256("${path.module}/../lambda.zip")
  timeout          = 3
  memory_size      = 128

  environment {
    variables = {
      OTEL_EXPORTER_OTLP_ENDPOINT      = var.otel_exporter_otlp_endpoint
      OTEL_EXPORTER_OTLP_LOGS_ENDPOINT = "https://${var.otel_exporter_otlp_endpoint}/v1/logs"
      HONEYCOMB_API_KEY                = var.honeycomb_api_key
      OTEL_SERVICE_NAME                = var.service_name
      HONEYCOMB_DATASET_NAME           = var.service_name
    }
  }
}

resource "aws_lambda_permission" "allow_apigateway_to_invoke_post_dua_lambda" {
  statement_id  = "AllowAPIGatewayInvokePostDua"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dua_requester.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
