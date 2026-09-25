output "api_management_id" {
  description = "API Management service resource ID."
  value       = local.effective_api_management_id
}

output "api_management_name" {
  description = "API Management service name."
  value       = local.effective_api_management_name
}

output "api_id" {
  description = "API resource ID."
  value       = azurerm_api_management_api.this.id
}

output "api_name" {
  description = "API name."
  value       = azurerm_api_management_api.this.name
}

output "gateway_url" {
  description = "Public API Management gateway URL."
  value       = local.effective_gateway_url
}

output "route_endpoints" {
  description = "Map of route names to public endpoints."
  value = {
    for route in var.routes : route.name => "${local.effective_gateway_url}/${var.path_prefix}${route.path}"
  }
}

output "routes" {
  description = "Route definitions with resolved public endpoints."
  value = {
    for route in var.routes : route.name => {
      path     = route.path
      methods  = [for method in route.methods : upper(method)]
      endpoint = "${local.effective_gateway_url}/${var.path_prefix}${route.path}"
      backend  = route.backend
    }
  }
}
