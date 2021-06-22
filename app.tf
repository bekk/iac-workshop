resource "azurerm_storage_account" "web" {
  name                     = "${var.unique_code}workshopweb"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
  }
}



resource "azurerm_app_service_plan" "appservice" {
  name                = "${var.unique_code}-workshop-sp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "app" {
  name                = "${var.unique_code}-terraform-app" 
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  app_service_plan_id = azurerm_app_service_plan.appservice.id
}
