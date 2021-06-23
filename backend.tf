resource "azurerm_app_service_plan" "appservice" {
  name                = local.unique_id
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  kind     = "Linux"
  reserved = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "app" {
  name                = local.unique_id
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  app_service_plan_id = azurerm_app_service_plan.appservice.id
}
