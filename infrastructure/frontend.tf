resource "azurerm_storage_account" "web" {
  name                      = local.unique_id_sanitized
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  allow_blob_public_access  = true # Be aware that this is not always what you want, this gives anyone with the url access
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  static_website {
    index_document = "index.html"
  }
}
