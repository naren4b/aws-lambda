terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==========================================================
# 1. GLOBAL VARIABLES
# ==========================================================
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project_name" {
  type    = string
  default = "nutriscan"
}

# Random suffix provider to solve global S3 naming constraints
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ==========================================================
# 2. AMAZON S3 STORAGE LAYER
# ==========================================================
resource "aws_s3_bucket" "nutriscan_storage" {
  bucket        = "${var.project_name}-storage-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = false
}

# Ensure modern bucket isolation by blocking generic public access
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.nutriscan_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==========================================================
# 3. AMAZON DYNAMODB METADATA STORE
# ==========================================================
resource "aws_dynamodb_table" "nutriscan_table" {
  name         = "${var.project_name}-scans-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # Serverless pay-as-you-go billing model
  hash_key     = "ScanID"

  attribute {
    name = "ScanID"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==========================================================
# 4. IAM SECURITY LAYER (LEAST PRIVILEGE POLICY)
# ==========================================================
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

# Custom policy allowing targeted interaction with specific storage, table, and AI endpoints
resource "aws_iam_policy" "lambda_permissions" {
  name        = "${var.project_name}-lambda-policy-${var.environment}"
  description = "Provides precise database writes, storage retrieval, and AI inference executions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [ "s3:GetObject" ]
        Resource = [ "${aws_s3_bucket.nutriscan_storage.arn}/*" ]
      },
      {
        Effect   = "Allow"
        Action   = [ "dynamodb:PutItem" ]
        Resource = [ aws_dynamodb_table.nutriscan_table.arn ]
      },
      {
        Effect   = "Allow"
        Action   = [ "bedrock:InvokeModel" ]
        Resource = [ "arn:aws:bedrock:${var.aws_region}::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0" ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_custom" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

# Attach native CloudWatch permissions to capture function logging streams
resource "aws_iam_role_policy_attachment" "attach_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ==========================================================
# 5. AWS LAMBDA COMPUTE LAYER
# ==========================================================
# Creating a dummy zip package initially to enable functional deployment without script errors
data "archive_file" "dummy_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda_dummy.zip"
  
  source {
    content  = "def lambda_handler(event, context): pass"
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "ingredient_analyzer" {
  function_name = "${var.project_name}-ingredient-analyzer" # Match function layout name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30 # Expanded runtime limit to account for processing duration fluctuations
  memory_size   = 512

  architectures = ["arm64"] # Enables cost-efficient ARM pricing tiers natively

  filename         = data.archive_file.dummy_lambda.output_path
  source_code_hash = data.archive_file.dummy_lambda.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.nutriscan_table.name
    }
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash] # Prevents configurations from overriding future code uploads
  }
}

# ==========================================================
# 6. ARCHITECTURAL OUTPUT DECLARATIONS
# ==========================================================
output "s3_bucket_name" {
  value       = aws_s3_bucket.nutriscan_storage.id
  description = "Target storage domain identifier"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.nutriscan_table.name
  description = "Target analytical tracking data table"
}

output "lambda_function_name" {
  value       = aws_lambda_function.ingredient_analyzer.function_name
  description = "Compute deployment identification tag"
}
