locals {
  unique_id_raw       = random_string.id.result
  unique_id           = "iac-workshop-${random_string.id.result}"
  unique_id_sanitized = replace(local.unique_id, "-", "")

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
