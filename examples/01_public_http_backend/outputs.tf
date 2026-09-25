output "api_management_id" {
  description = "API Management service resource ID."
  value       = module.api_management.api_management_id
}

output "gateway_url" {
  description = "Public API Management gateway URL."
  value       = module.api_management.gateway_url
}

output "route_endpoints" {
  description = "Resolved route endpoints."
  value       = module.api_management.route_endpoints
}
