# TODO: Consider CDN
resource "azurerm_storage_account" "web" {
  name                      = local.unique_id_sanitized
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  allow_blob_public_access  = true # Be aware that this is not always what you want
  enable_https_traffic_only = false
  min_tls_version           = "TLS1_2"

  custom_domain {
    name          = local.web_hostname
    use_subdomain = false
  }

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.web.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content = templatefile("${path.module}/templates/index.html.tmpl", {
    unique_id = local.unique_id
  })
}
