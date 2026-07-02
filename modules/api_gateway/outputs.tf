output "api_id" {
  description = "HTTP API ID."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Base API endpoint."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "stage_invoke_url" {
  description = "Stage invoke URL."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "access_log_group_name" {
  description = "Access log group name."
  value       = aws_cloudwatch_log_group.api.name
}
