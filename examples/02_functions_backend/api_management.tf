module "api_management" {
  source = "../../"

  name                = "fk-apim-fn-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  subscription_required = false

  routes = [
    {
      name    = "fncustom1"
      path    = "/fncustom1"
      methods = ["POST"]
      backend = {
        type        = "FUNCTION_BACKEND"
        function_id = "${module.function.id}/functions/fncustom1"
      }
    },
    {
      name    = "fncustom2"
      path    = "/fncustom2"
      methods = ["POST"]
      backend = {
        type        = "FUNCTION_BACKEND"
        function_id = "${module.function.id}/functions/fncustom2"
      }
    }
  ]

  tags = var.tags
}
