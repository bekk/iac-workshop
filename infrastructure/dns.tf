locals {
  # Hopefully z6-prefix won't change
  assumed_storage_account_web_host = "${local.unique_id_sanitized}.z6.web.core.windows.net"
}

// If the workshop is run externally, these values should be changed
data "azurerm_dns_zone" "cloudlabs_azure_no" {
  name                = "cloudlabs-azure.no"
  resource_group_name = "workshop-admin"
}

resource "azurerm_dns_cname_record" "www" {
  zone_name           = data.azurerm_dns_zone.cloudlabs_azure_no.name
  resource_group_name = data.azurerm_dns_zone.cloudlabs_azure_no.resource_group_name

  ttl    = 60
  name   = local.unique_id_raw
  record = "${azurerm_cdn_endpoint.cdn_endpoint.name}.azureedge.net"
}

resource "azurerm_cdn_endpoint_custom_domain" "cloudlabs_custom_domain" {
  name            = local.unique_id_raw
  cdn_endpoint_id = azurerm_cdn_endpoint.cdn_endpoint.id
  host_name       = "${local.unique_id_raw}.${data.azurerm_dns_zone.cloudlabs_azure_no.name}"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}
