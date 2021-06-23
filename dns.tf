data "azurerm_dns_zone" "rettiprod_live" {
  name                = "rettiprod.live"
  resource_group_name = "rett-i-prod-admin"
}

resource "azurerm_dns_cname_record" "www" {
  zone_name           = data.azurerm_dns_zone.rettiprod_live.name
  resource_group_name = data.azurerm_dns_zone.rettiprod_live.resource_group_name

  ttl    = 60
  name   = local.unique_id_raw
  record = azurerm_storage_account.web.primary_web_host
}
