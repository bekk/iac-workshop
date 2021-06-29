locals {
  # Hopefully z6-prefix won't change
  assumed_storage_account_web_host = "${local.unique_id_sanitized}.z6.web.core.windows.net"
}

// If the workshop is run externally, these values should be changed
data "azurerm_dns_zone" "rettiprod_live" {
  name                = "rettiprod.live"
  resource_group_name = "rett-i-prod-admin"
}

resource "azurerm_dns_cname_record" "www" {
  zone_name           = data.azurerm_dns_zone.rettiprod_live.name
  resource_group_name = data.azurerm_dns_zone.rettiprod_live.resource_group_name

  ttl    = 60
  name   = local.unique_id_raw
  record = local.assumed_storage_account_web_host
}
