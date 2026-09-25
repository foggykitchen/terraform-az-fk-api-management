data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

module "function" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-function.git?ref=main"

  name                       = "fk-fn-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  service_plan_name          = "fk-fn-plan-${random_string.suffix.result}"
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  zip_deploy_file            = data.archive_file.function.output_path
  runtime_stack = {
    language = "python"
    version  = "3.12"
  }
  tags = var.tags
}
