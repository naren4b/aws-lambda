# =========================================================================
# AWS LAMBDA POWER TUNING MODULE (DECOUPLED STACK)
# =========================================================================

# Automatically discover the official Power Tuning tool in the Serverless App Repo (SAR)
data "aws_serverlessapplicationrepository_application" "power_tuning" {
  application_id = "arn:aws:serverlessrepo:us-east-1:451282441545:applications~aws-lambda-power-tuning" [cite: 783, 820]
}

# Provision the optimization engine as an isolated CloudFormation stack via SAR
resource "aws_serverlessapplicationrepository_cloudformation_stack" "lambda_power_tuning" {
  name             = "${var.project_name}-power-tuning-${var.environment}" [cite: 820]
  application_id   = data.aws_serverlessapplicationrepository_application.power_tuning.application_id [cite: 820]
  semantic_version = data.aws_serverlessapplicationrepository_application.power_tuning.semantic_version [cite: 820]
  capabilities     = data.aws_serverlessapplicationrepository_application.power_tuning.capabilities [cite: 820]

  # Pass downstream target bindings linking the engine to your core computing layer
  parameters = {
    # Natively references the target Lambda ARN exposed by your independent main.tf definitions
    lambdaResource       = aws_lambda_function.ingredient_analyzer.arn [cite: 820]
    
    # Enables data visualization endpoints to output cost vs. performance graphs
    visualizationEnabled = "true" [cite: 820]
    
    # Leave empty if your processing function does not require specialized VPC routing configurations
    securityGroupIds     = "" [cite: 820]
    subnetIds            = "" [cite: 820]
  }
}

# =========================================================================
# INDEPENDENT OPTIMIZATION OUTPUT MARSHALLING
# =========================================================================

output "power_tuning_state_machine_arn" {
  value       = aws_serverlessapplicationrepository_cloudformation_stack.lambda_power_tuning.outputs["StateMachineARN"] [cite: 823]
  description = "The target AWS Step Functions ARN to execute your benchmarking suite." [cite: 823]
}

output "power_tuning_visualization_url" {
  value       = aws_serverlessapplicationrepository_cloudformation_stack.lambda_power_tuning.outputs["VisualizationURL"] [cite: 823]
  description = "The baseline web domain address used to render your custom optimization results." [cite: 823]
}
