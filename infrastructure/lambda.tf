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

data "archive_file" "do_nothing_lambda_go_source" {
  type        = "zip"
  output_path = "do-nothing-lambda.zip"
  source {
    content  = <<-EOT
    package main

    import (
      "context"
      "github.com/aws/aws-lambda-go/lambda"
    )

    func Handler(ctx context.Context) (string, error) {
      // This function does nothing.
      return "{\"statusCode\": 200, \"body\": \"\"}", nil
    }

    func main() {
      lambda.Start(Handler)
    }
    EOT
    filename = "main.go"
  }
}

resource "aws_lambda_function" "dua_requester" {
  function_name = var.service_name
  runtime       = "provided.al2" # Or provided.al2023 for Go 1.x custom runtime
  handler       = "bootstrap"    # Your Go binary
  filename      = data.archive_file.do_nothing_lambda_go_source.output_path
  role          = aws_iam_role.lambda_exec_role.arn # Assuming you have a role

  source_code_hash = data.archive_file.do_nothing_lambda_go_source.output_base64sha256
  timeout          = 3
  memory_size      = 128
}

resource "aws_lambda_permission" "allow_apigateway_to_invoke_post_dua_lambda" {
  statement_id  = "AllowAPIGatewayInvokePostDua"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dua_requester.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
