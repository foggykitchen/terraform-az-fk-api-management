output "api_management_id" {
  description = "API Management service resource ID."
  value       = module.api_management.api_management_id
}

output "function_app_id" {
  description = "Composed Function App resource ID."
  value       = module.function.id
}

output "route_endpoints" {
  description = "Resolved Function route endpoints."
  value       = module.api_management.route_endpoints
}
