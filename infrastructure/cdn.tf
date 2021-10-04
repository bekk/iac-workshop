resource "azurerm_cdn_profile" "cdn_profile" {
  name                = "iac-workshop-cdn-profile"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # Microsoft is the fastest of the providers available for Pay-as-you-go subscriptions
  sku = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = "${local.unique_id_sanitized}-cdn-endpoint" # has to be unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  origin_host_header  = azurerm_storage_account.web.primary_web_host
  origin {
    name      = "origin"
    host_name = azurerm_storage_account.web.primary_web_host
  }

  global_delivery_rule {
    cache_expiration_action {
      behavior = "BypassCache"
    }
  }
}
