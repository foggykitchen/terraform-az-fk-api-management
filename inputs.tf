variable "name" {
  description = "Base name used for the API Management service and API."
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "resource_group_name" {
  description = "Resource group for a new API Management service. Ignored when attaching to an existing service."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for a new API Management service. Ignored when attaching to an existing service."
  type        = string
  default     = null
}

variable "create_api_management" {
  description = "Whether the module creates a Consumption-tier API Management service."
  type        = bool
  default     = true
}

variable "api_management_id" {
  description = "Existing API Management service resource ID. Required when create_api_management is false."
  type        = string
  default     = null
}

variable "api_management_name" {
  description = "Optional API Management service name override when creating the service."
  type        = string
  default     = null
}

variable "publisher_name" {
  description = "Publisher/company name required when creating the API Management service."
  type        = string
  default     = null
}

variable "publisher_email" {
  description = "Publisher email required when creating the API Management service."
  type        = string
  default     = null
}

variable "api_name" {
  description = "Optional internal API name override."
  type        = string
  default     = null
}

variable "api_display_name" {
  description = "Optional API display name override."
  type        = string
  default     = null
}

variable "path_prefix" {
  description = "API path prefix without leading or trailing slashes."
  type        = string
  default     = "v1"

  validation {
    condition     = trim(var.path_prefix, "/") != "" && var.path_prefix == trim(var.path_prefix, "/")
    error_message = "path_prefix must be non-empty and must not start or end with '/'."
  }
}

variable "subscription_required" {
  description = "Whether callers must supply an APIM subscription key. Defaults to anonymous/public parity with the OCI example."
  type        = bool
  default     = false
}

variable "routes" {
  description = "API routes. FUNCTION_BACKEND function_id values must be Azure Function resource IDs ending in /functions/{function-name}."
  type = list(object({
    name    = string
    path    = string
    methods = list(string)
    backend = object({
      type        = string
      function_id = optional(string)
      url         = optional(string)
    })
  }))

  validation {
    condition     = length(var.routes) > 0
    error_message = "At least one route must be defined."
  }

  validation {
    condition     = length(distinct([for route in var.routes : route.name])) == length(var.routes)
    error_message = "Each route name must be unique."
  }

  validation {
    condition = alltrue([
      for route in var.routes :
      trimspace(route.name) != "" && startswith(route.path, "/") && length(route.methods) > 0
    ])
    error_message = "Each route needs a non-empty name, a path beginning with '/', and at least one method."
  }

  validation {
    condition = alltrue(flatten([
      for route in var.routes : [
        for method in route.methods : contains(["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "TRACE"], upper(method))
      ]
    ]))
    error_message = "Route methods must be valid HTTP methods."
  }

  validation {
    condition = alltrue([
      for route in var.routes : length(distinct([for method in route.methods : upper(method)])) == length(route.methods)
    ])
    error_message = "A route must not repeat an HTTP method."
  }

  validation {
    condition = alltrue([
      for route in var.routes : contains(["HTTP_BACKEND", "FUNCTION_BACKEND"], route.backend.type)
    ])
    error_message = "Supported backend types are HTTP_BACKEND and FUNCTION_BACKEND."
  }

  validation {
    condition = alltrue([
      for route in var.routes :
      route.backend.type != "HTTP_BACKEND" || (
        try(route.backend.url, null) != null && can(regex("^https://[^/]+", route.backend.url))
      )
    ])
    error_message = "HTTP_BACKEND routes must define an HTTPS backend.url."
  }

  validation {
    condition = alltrue([
      for route in var.routes :
      route.backend.type != "FUNCTION_BACKEND" || (
        try(route.backend.function_id, null) != null &&
        can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Web/sites/[^/]+/functions/[^/]+$", route.backend.function_id))
      )
    ])
    error_message = "FUNCTION_BACKEND routes must define a full Azure Function resource ID ending in /functions/{function-name}."
  }
}

variable "function_keys" {
  description = "Optional Function host or function keys keyed by route name. Keys are stored as secret APIM named values and sent as x-functions-key."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for route_name in keys(var.function_keys) : contains([
        for route in var.routes : route.name if route.backend.type == "FUNCTION_BACKEND"
      ], route_name)
    ])
    error_message = "function_keys keys must match FUNCTION_BACKEND route names."
  }
}

variable "tags" {
  description = "Tags assigned to a newly created API Management service."
  type        = map(string)
  default     = {}
}
