locals {
  frontend_dir   = "${path.module}/../frontend"
  frontend_files = fileset(local.frontend_dir, "**")
  frontend_src = {
    for fn in local.frontend_files :
    fn => filemd5("${local.frontend_dir}/${fn}") if(length(regexall("(node_modules/.*)|build/.*", fn)) == 0)
  }

  // TODO: Download a MIME list + embed
  mime_types = {
    ".gif"  = "image/gif"
    ".html" = "text/html"
    ".ico"  = "image/vnd.microsoft.icon"
    ".jpeg" = "image/jpeg"
    ".jpg"  = "image/jpeg"
    ".js"   = "text/javascript"
    ".json" = "application/json"
    ".map"  = "application/json"
    ".png"  = "image/png"
    ".txt"  = "text/plain"
  }
}

resource "azurerm_storage_account" "web" {
  name                            = local.unique_id_sanitized
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true # Be aware that this is not always what you want, this gives anyone with the url access
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  static_website {
    index_document = "index.html"
  }
}

// Upload the latest built assets
resource "azurerm_storage_blob" "payload" {
  for_each               = fileset("${local.frontend_dir}/build", "**")
  name                   = each.value
  storage_account_name   = azurerm_storage_account.web.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${local.frontend_dir}/build/${each.value}"
  content_md5            = filemd5("${local.frontend_dir}/build/${each.value}")
  content_type           = lookup(local.mime_types, regex("\\.[^.]+$", basename(each.value)), null) // use known MIME type or fallback to default
}
