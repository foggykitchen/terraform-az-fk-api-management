variable "resource_group_name" {
  description = "Resource group name."
  type        = string
  default     = "fk-api-management-http-rg"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "publisher_name" {
  description = "API publisher/company name."
  type        = string
  default     = "FoggyKitchen"
}

variable "publisher_email" {
  description = "API publisher email."
  type        = string
  default     = "training@example.com"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    project = "foggykitchen"
    env     = "dev"
  }
}
