module "api_management" {
  source = "../../"

  name                = "fk-apim-http-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  subscription_required = false

  routes = [
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

  tags = var.tags
}
