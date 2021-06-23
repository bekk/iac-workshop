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

# TODO: Loop contents
resource "azurerm_storage_blob" "static-files" {
  for_each               = fileset("${path.module}/payload", "*")
  name                   = each.key
  storage_account_name   = azurerm_storage_account.web.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html" # TODO: Dynamic mimetype
  source_content         = file("${path.module}/payload/${each.key}")

  depends_on = [null_resource.frontend-payload]
}

resource "null_resource" "frontend-payload" {
  triggers = {
    src = var.frontend_zip
  }

  provisioner "local-exec" {
    # TODO: frontend zip is not actually used yet
    command = "${path.module}/frontend.sh ${var.frontend_zip} http://${azurerm_container_group.backend.fqdn}:8080/api"
  }
}
