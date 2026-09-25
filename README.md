# terraform-az-fk-api-management

This repository contains a reusable Terraform / OpenTofu module and focused examples for deploying Azure API Management APIs with HTTP and Azure Function backends.

It is part of the [FoggyKitchen.com training ecosystem](https://foggykitchen.com/) and is the Azure counterpart to `terraform-oci-fk-api-gateway`.

Support expectations are documented in [SUPPORT.md](SUPPORT.md).

---

## Purpose

The module provides a small, typed API-fronting boundary while hiding Azure API Management's policy-document implementation:

- Creates or attaches to an API Management service
- Creates one API and one operation per route/method combination
- Supports generic HTTPS and Azure Function backends
- Generates all backend-selection and URL-rewrite policy XML internally

This is not a full API platform, identity layer, or networking module.

---

## What the module does

The module creates:

- A Consumption-tier API Management service (`azurerm_api_management`), unless `create_api_management = false`
- One API (`azurerm_api_management_api`)
- One operation per route/method (`azurerm_api_management_api_operation`)
- One backend per route (`azurerm_api_management_backend`)
- One generated operation policy per operation (`azurerm_api_management_api_operation_policy`)
- Optional secret named values for caller-supplied Function keys (`azurerm_api_management_named_value`)

The module intentionally does not create:

- VNets or subnets
- Function Apps or functions
- Function keys, managed identities, IAM/RBAC role assignments, or Function authentication configuration needed for invocation
- Load Balancers, Application Gateway, or Front Door
- Products, subscriptions, users, OAuth providers, or client identity infrastructure

Those concerns belong in focused modules or composition layers.

---

## Provider Notes

The contract was verified against AzureRM `4.81.0`, the latest 4.x version selected on 2026-09-24 by the FoggyKitchen constraint `>= 3.100.0, < 5.0.0`. AzureRM 5.x exists, but current FoggyKitchen Azure modules deliberately retain the shared `< 5.0.0` compatibility boundary.

AzureRM requires `publisher_name`, `publisher_email`, and `sku_name` when creating API Management. Consumption uses the exact SKU string `Consumption_0`; its capacity is zero because Azure scales it automatically.

Consumption is a public, serverless gateway tier. Microsoft currently documents no inbound private endpoint, VNet injection, or outbound VNet integration for it. Consequently, this module exposes no misleading `endpoint_type` or subnet input. Choose an APIM tier with supported networking in a different composition when private client or private backend connectivity is required. Consumption also has no fixed capacity units and may have cold-start latency; provisioning an APIM service can take tens of minutes, so allow for a long create operation.

The API defaults to `subscription_required = false`, matching the anonymous OCI minimal example. Set it to `true` when an APIM subscription key should be required; product/subscription lifecycle remains outside this module.

### Function authentication

Microsoft's current simple Function import flow creates a Function host key, stores it as an APIM secret named value, and sends it to the Function in the `x-functions-key` header. This module supports the same mechanism through the optional sensitive `function_keys` map. The map is keyed by route name, allowing routes to reference Function IDs that are unknown until apply; the secret is never embedded in policy XML.

Managed-identity backend authentication avoids Function keys and is preferred when the Function is deliberately protected by Microsoft Entra ID, but it also requires APIM identity configuration, Function authentication, an audience, and role/access configuration. Those cross-service identity concerns are intentionally outside this minimal module. Anonymous Functions need no `function_keys` entry.

---

## Design Notes

OCI API Gateway accepts a typed backend directly on each route. Azure API Management instead selects a backend through a policy applied to an API operation. The public contract remains intentionally OCI-like:

```hcl
routes = list(object({
  name    = string
  path    = string
  methods = list(string)
  backend = object({
    type        = string
    function_id = optional(string)
    url         = optional(string)
  })
}))
```

Internally, the module creates one `azurerm_api_management_backend` per route, expands every route method into an operation, and renders `templates/operation-policy.xml.tftpl` for each operation. Route-name-based backend keys remain known during planning even when a newly created Function ID is not known until apply. The generated `<set-backend-service>` chooses the backend, while `<rewrite-uri>` preserves OCI-style exact target URLs. Consumers never write or pass policy XML.

`FUNCTION_BACKEND` expects a Function resource ID ending in `/functions/{function-name}`. The conventional public invoke URL is derived as `https://{function-app}.azurewebsites.net/api/{function-name}`. Use `HTTP_BACKEND` when a Function uses a custom hostname or nonstandard route.

---

## Repository Structure

```text
terraform-az-fk-api-management/
├── examples/
│   ├── 01_public_http_backend/
│   ├── 02_functions_backend/
│   └── README.md
├── templates/
│   └── operation-policy.xml.tftpl
├── main.tf
├── inputs.tf
├── outputs.tf
├── versions.tf
├── SUPPORT.md
├── LICENSE
└── README.md
```

---

## Example Usage

```hcl
module "api_management" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-api-management.git?ref=v0.1.0"

  name                = "fk-api-gateway"
  resource_group_name = "fk-api-rg"
  location            = "westeurope"
  publisher_name      = "FoggyKitchen"
  publisher_email     = "training@example.com"

  routes = [
    {
      name    = "fncustom1"
      path    = "/fncustom1"
      methods = ["POST"]
      backend = {
        type        = "FUNCTION_BACKEND"
        function_id = var.function_id
      }
    },
    {
      name    = "health"
      path    = "/health"
      methods = ["GET"]
      backend = {
        type = "HTTP_BACKEND"
        url  = "https://httpbin.org/status/200"
      }
    }
  ]
}
```

To attach to an existing APIM service, set `create_api_management = false` and pass its full `api_management_id`. The service name and Resource Group are derived from that ID.

---

## Module Inputs

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | `string` | yes | Base name used for the APIM service and API |
| `resource_group_name` | `string` | when creating | Resource Group for a new APIM service |
| `location` | `string` | when creating | Azure region for a new APIM service |
| `create_api_management` | `bool` | no | Whether to create a Consumption-tier APIM service |
| `api_management_id` | `string` | when attaching | Existing APIM service resource ID |
| `api_management_name` | `string` | no | Optional created APIM service name override |
| `publisher_name` | `string` | when creating | APIM publisher/company name |
| `publisher_email` | `string` | when creating | APIM publisher email |
| `api_name` | `string` | no | Optional internal API name override |
| `api_display_name` | `string` | no | Optional API display name override |
| `path_prefix` | `string` | no | API path prefix without surrounding slashes |
| `subscription_required` | `bool` | no | Whether APIM subscription keys are required |
| `routes` | `list(object({ name = string, path = string, methods = list(string), backend = object({ type = string, function_id = optional(string), url = optional(string) }) }))` | yes | Typed HTTP or Function route definitions |
| `function_keys` | `map(string)` (sensitive) | no | Function keys keyed by `FUNCTION_BACKEND` route name |
| `tags` | `map(string)` | no | Tags for a newly created APIM service |

Supported backend types are `HTTP_BACKEND` with `backend.url`, and `FUNCTION_BACKEND` with `backend.function_id`.

---

## Module Outputs

| Output | Description |
|--------|-------------|
| `api_management_id` | API Management service resource ID |
| `api_management_name` | API Management service name |
| `api_id` | API resource ID |
| `api_name` | API name |
| `gateway_url` | Public API Management gateway URL |
| `route_endpoints` | Map of route names to public endpoints |
| `routes` | Route definitions with resolved public endpoints |

---

## Examples

- `01_public_http_backend`: public Consumption APIM with one HTTP operation
- `02_functions_backend`: two Function operations composed with `terraform-az-fk-function`

See [examples/README.md](examples/README.md).

---

## Composition Requirements

Callers own the backend services and their access model. For a key-protected Function, create or retrieve an appropriate host/function key and pass it through a sensitive value (not a committed tfvars file). For Entra-protected Functions, configure APIM identity, Function authentication, and least-privilege access in the composition layer. Consumption APIM can reach only publicly reachable backends.

---

## Design Philosophy

- Explicit over implicit
- Small modules over monoliths
- API gateway concerns separated from networking, backends, identity, and client access
- Optimized for learning, reuse, and composition

---

## License

Licensed under the Universal Permissive License (UPL), Version 1.0.
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
