# Azure API Management with Terraform/OpenTofu - Training Examples

This directory contains progressive free examples used with the **terraform-az-fk-api-management** module.
The examples are designed as incremental building blocks for public API-fronting architectures on Azure.

These examples are part of the [FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses-2/) and are meant to be applied independently for learning and experimentation.

---

## Example Overview

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| 01 | **Public HTTP Backend** | Consumption tier, public HTTPS backend, anonymous API, generated operation policy |
| 02 | **Functions Backend** | FoggyKitchen Function module, two Python HTTP triggers, ZIP deployment, generated Function backend policies |

---

## How to Use

Each example directory contains:

- Terraform/OpenTofu configuration split by resource concern (`.tf`)
- A focused `README.md` explaining the goal, service layout, runtime behavior, and verification steps
- A `terraform.tfvars.example` file containing only non-secret values
- An independently created Resource Group and globally unique API Management service name
- For Example 02, a small Python Function package under `function/`

To run an example:

```bash
cd examples/01_public_http_backend
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan
tofu apply
```

The current free learning path contains these focused examples:

```text
01
02
```

Each example owns an independent state and can be deployed separately. Larger event-driven compositions belong in FoggyKitchen landing zones or blueprints, not in free module examples.

API Management provisioning can take tens of minutes. The examples use the serverless Consumption tier, but service creation is still a long-running Azure control-plane operation.

---

## Design Principles

- One example = one architectural goal
- API routes use the same small typed backend contract as the OCI counterpart
- Backend resources and operation policy XML are implementation details of the root module
- Consumers never need to write `<set-backend-service>` or `<rewrite-uri>` policies
- Example 01 uses an existing public HTTP service; it does not own the backend
- Example 02 composes Function infrastructure through `terraform-az-fk-function`
- Examples require no secrets in `terraform.tfvars`
- Function keys, when required outside the anonymous example, flow through sensitive variables and secret APIM named values
- The API defaults to anonymous access for OCI example parity; subscription-key enforcement is an explicit toggle
- Consumption-tier APIM is public-only and cannot reach private VNet-isolated backends
- Networking, Private Endpoints, identity, RBAC, products, subscriptions, Application Gateway, Front Door, Load Balancers, and CI/CD remain outside this module

---

## Blueprint Candidates

Advanced Azure API Management scenarios should be modeled as FoggyKitchen landing zones or blueprints:

- Event-driven data pipelines combining API Management, Functions, Event Grid, Event Hubs, and a database
- Microsoft Entra-protected Function backends using APIM managed identity
- Subscription, product, quota, rate-limit, and consumer onboarding lifecycles
- Private API platforms using an APIM tier that supports Private Endpoint or VNet integration
- API Management behind Azure Front Door or Application Gateway
- Custom domains, certificates, Key Vault integration, diagnostics, and centralized monitoring
- Multi-region API exposure and disaster recovery

---

## Related Resources

- [FoggyKitchen Azure API Management Module](../)
- [FoggyKitchen Azure Function Module](https://github.com/foggykitchen/terraform-az-fk-function)
- [FoggyKitchen Azure Event Grid Module](https://github.com/foggykitchen/terraform-az-fk-event-grid)
- [FoggyKitchen Azure Event Hubs Module](https://github.com/foggykitchen/terraform-az-fk-event-hub)
- [FoggyKitchen Azure Managed Identity Module](https://github.com/foggykitchen/terraform-az-fk-managed-identity)
- [FoggyKitchen Azure RBAC Module](https://github.com/foggykitchen/terraform-az-fk-rbac)
- [FoggyKitchen Azure Key Vault Module](https://github.com/foggykitchen/terraform-az-fk-key-vault)
- [FoggyKitchen OCI API Gateway Module](https://github.com/foggykitchen/terraform-oci-fk-api-gateway)

---

## License

Licensed under the Universal Permissive License (UPL), Version 1.0.
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
