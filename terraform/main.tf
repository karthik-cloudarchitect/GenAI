# =============================================================================
# GenAI AWS Lambda Function - Terraform Configuration
# =============================================================================
# This configuration deploys an AI-powered Lambda function for generating
# EKS (Elastic Kubernetes Service) commands using AWS Bedrock.
#
# Components:
# - Lambda execution role with necessary permissions
# - Lambda function with AI model integration
# - CloudWatch logs for monitoring
# - API Gateway for HTTP endpoints (if needed)
#
# Use Case: Generate kubectl commands and EKS management scripts using AI
# Model Integration: AWS Bedrock for natural language processing
# Region: ap-southeast-2 (Sydney)
# =============================================================================

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "eks-genai-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# You can add Bedrock permissions later like this:
# resource "aws_iam_role_policy_attachment" "bedrock" {
#   role       = aws_iam_role.lambda_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
# }

resource "aws_lambda_function" "eks_genai" {
  function_name    = "eks-genai-handler"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = "${path.module}/function.zip"
  source_code_hash = filebase64sha256("${path.module}/function.zip")
}

resource "aws_iam_role_policy_attachment" "bedrock" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

resource "aws_api_gateway_rest_api" "eks_genai_api" {
  name        = "eks-genai-api"
  description = "API Gateway for EKS GenAI Lambda"
}

resource "aws_api_gateway_resource" "eks_genai_resource" {
  rest_api_id = aws_api_gateway_rest_api.eks_genai_api.id
  parent_id   = aws_api_gateway_rest_api.eks_genai_api.root_resource_id
  path_part   = "generate"
}

resource "aws_api_gateway_method" "eks_genai_method" {
  rest_api_id   = aws_api_gateway_rest_api.eks_genai_api.id
  resource_id   = aws_api_gateway_resource.eks_genai_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "eks_genai_integration" {
  rest_api_id             = aws_api_gateway_rest_api.eks_genai_api.id
  resource_id             = aws_api_gateway_resource.eks_genai_resource.id
  http_method             = aws_api_gateway_method.eks_genai_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.eks_genai.invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eks_genai.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.eks_genai_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "eks_genai_deployment" {
  depends_on  = [aws_api_gateway_integration.eks_genai_integration]
  rest_api_id = aws_api_gateway_rest_api.eks_genai_api.id
}

resource "aws_api_gateway_stage" "eks_genai_stage" {
  deployment_id = aws_api_gateway_deployment.eks_genai_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.eks_genai_api.id
  stage_name    = "dev"
}

output "api_gateway_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.eks_genai_api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.eks_genai_stage.stage_name}/generate"
}

