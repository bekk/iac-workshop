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
  record = "${azurerm_cdn_endpoint.cdn_endpoint.name}.azureedge.net"
}

resource "azurerm_cdn_endpoint_custom_domain" "rettiprod_custom_domain" {
  name            = local.unique_id_raw
  cdn_endpoint_id = azurerm_cdn_endpoint.cdn_endpoint.id
  host_name       = "${local.unique_id_raw}.${data.azurerm_dns_zone.rettiprod_live.name}"

  # Waiting for https://github.com/hashicorp/terraform-provider-azurerm/pull/13283
  # Also, ARM templates do not have an option to add HTTPS: https://docs.microsoft.com/en-us/azure/templates/microsoft.cdn/profiles/endpoints/customdomains
  # So in the meantime, this will have to do
  provisioner "local-exec" {
    command = "az cdn custom-domain enable-https --endpoint-name ${azurerm_cdn_endpoint.cdn_endpoint.name} --name ${azurerm_cdn_endpoint_custom_domain.rettiprod_custom_domain.name} --profile-name ${azurerm_cdn_profile.cdn_profile.name} --resource-group ${azurerm_resource_group.rg.name}"
  }
}