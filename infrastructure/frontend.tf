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

  depends_on = [azurerm_dns_cname_record.www]
}

locals {
  filetype_endings = {
    js   = "application/javascript"
    ico  = "image/x-icon"
    html = "text/html"
    json = "application/json"
    map  = "application/json"
    js   = "application/javascript"
    txt  = "text/plain"
  }
}

/*
resource "azurerm_storage_blob" "static-files" {
  for_each               = fileset("${path.module}/payload", "**")
  name                   = each.key
  storage_account_name   = azurerm_storage_account.web.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = local.filetype_endings[regex("[a-z]+$", "${each.key}")]
  source = "${path.module}/payload/${each.key}"

  # Forces recreation if the file contents changes
  content_md5 = filemd5("${path.module}/payload/${each.key}")

  depends_on = [null_resource.frontend-payload]

}
*/

resource "null_resource" "frontend-payload" {
  triggers = {
    // TODO: Some stort of stable trigger?
    build_time = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/frontend.sh ${var.frontend_zip} http://${azurerm_container_group.backend.fqdn}:8080/api ${azurerm_storage_account.web.name} ${azurerm_storage_account.web.primary_access_key}"
  }
}
