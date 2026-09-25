locals {
  effective_api_management_id = var.create_api_management ? azurerm_api_management.this[0].id : var.api_management_id
  effective_api_management_name = var.create_api_management ? azurerm_api_management.this[0].name : (
    var.api_management_id == null ? null : element(split("/", var.api_management_id), 8)
  )
  effective_resource_group_name = var.create_api_management ? azurerm_api_management.this[0].resource_group_name : (
    var.api_management_id == null ? null : element(split("/", var.api_management_id), 4)
  )
  effective_gateway_url = var.create_api_management ? azurerm_api_management.this[0].gateway_url : (
    local.effective_api_management_name == null ? null : "https://${local.effective_api_management_name}.azure-api.net"
  )

  resolved_api_name         = coalesce(var.api_name, var.name)
  resolved_api_display_name = coalesce(var.api_display_name, var.name)

  backends = {
    for route in var.routes : route.name => {
      route_name = route.name
      name       = "backend-${substr(sha1(route.name), 0, 12)}"
      type       = route.backend.type
      target     = route.backend.type == "FUNCTION_BACKEND" ? route.backend.function_id : route.backend.url
      origin = route.backend.type == "FUNCTION_BACKEND" ? (
        "https://${element(split("/", route.backend.function_id), 8)}.azurewebsites.net"
      ) : regex("^https://[^/]+", route.backend.url)
      target_path = route.backend.type == "FUNCTION_BACKEND" ? (
        "/api/${element(split("/", route.backend.function_id), 10)}"
      ) : trimprefix(route.backend.url, regex("^https://[^/]+", route.backend.url))
    }
  }

  operations = merge([
    for route in var.routes : {
      for method in route.methods : "${route.name}-${lower(method)}" => {
        route_name  = route.name
        path        = route.path
        method      = upper(method)
        backend_key = route.name
      }
    }
  ]...)
}

resource "azurerm_api_management" "this" {
  count = var.create_api_management ? 1 : 0

  name                = coalesce(var.api_management_name, var.name)
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Consumption_0"
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.location != null && var.resource_group_name != null
      error_message = "location and resource_group_name are required when create_api_management is true."
    }

    precondition {
      condition     = var.publisher_name != null && var.publisher_email != null
      error_message = "publisher_name and publisher_email are required when create_api_management is true."
    }
  }
}

resource "azurerm_api_management_api" "this" {
  name                  = local.resolved_api_name
  resource_group_name   = local.effective_resource_group_name
  api_management_name   = local.effective_api_management_name
  revision              = "1"
  display_name          = local.resolved_api_display_name
  path                  = var.path_prefix
  protocols             = ["https"]
  subscription_required = var.subscription_required

  lifecycle {
    precondition {
      condition = var.create_api_management || (
        var.api_management_id != null &&
        can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.ApiManagement/service/[^/]+$", var.api_management_id))
      )
      error_message = "api_management_id must be a full API Management service resource ID when create_api_management is false."
    }
  }
}

resource "azurerm_api_management_named_value" "function_key" {
  for_each = {
    for route_name in keys(nonsensitive(var.function_keys)) : route_name => local.backends[route_name]
  }

  name                = "function-key-${substr(sha1(each.key), 0, 12)}"
  resource_group_name = local.effective_resource_group_name
  api_management_name = local.effective_api_management_name
  display_name        = "function-key-${substr(sha1(each.key), 0, 12)}"
  secret              = true
  value               = var.function_keys[each.key]
}

resource "azurerm_api_management_backend" "this" {
  for_each = local.backends

  name                = each.value.name
  resource_group_name = local.effective_resource_group_name
  api_management_name = local.effective_api_management_name
  protocol            = "http"
  url                 = each.value.origin
  resource_id = each.value.type == "FUNCTION_BACKEND" ? (
    "https://management.azure.com${dirname(dirname(each.value.target))}"
  ) : null

  dynamic "credentials" {
    for_each = contains(keys(azurerm_api_management_named_value.function_key), each.key) ? [each.key] : []

    content {
      header = {
        "x-functions-key" = "{{${azurerm_api_management_named_value.function_key[each.key].name}}}"
      }
    }
  }
}

resource "azurerm_api_management_api_operation" "this" {
  for_each = local.operations

  operation_id        = each.key
  api_name            = azurerm_api_management_api.this.name
  api_management_name = local.effective_api_management_name
  resource_group_name = local.effective_resource_group_name
  display_name        = "${each.value.route_name} ${each.value.method}"
  method              = each.value.method
  url_template        = each.value.path
}

resource "azurerm_api_management_api_operation_policy" "this" {
  for_each = local.operations

  api_name            = azurerm_api_management_api.this.name
  api_management_name = local.effective_api_management_name
  resource_group_name = local.effective_resource_group_name
  operation_id        = azurerm_api_management_api_operation.this[each.key].operation_id
  xml_content = templatefile("${path.module}/templates/operation-policy.xml.tftpl", {
    backend_id = azurerm_api_management_backend.this[each.value.backend_key].name
    target_path = (
      local.backends[each.value.backend_key].target_path == "" ? "/" : local.backends[each.value.backend_key].target_path
    )
  })
}
