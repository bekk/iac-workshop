locals {
  resource_prefix     = "iac-workshop-"
  unique_id_raw       = random_string.id.result
  unique_id           = "${local.resource_prefix}${random_string.id.result}"
  unique_id_sanitized = replace(local.unique_id, "-", "") # Some resources only support alphanumeric characters, and not '-'

  web_hostname = "${local.unique_id_raw}.rettiprod.live"
}

resource "random_string" "id" {
  length  = 8
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = local.unique_id
  location = var.location
}
