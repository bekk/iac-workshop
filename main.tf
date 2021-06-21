terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = "okp-terraform-workshop-test"
  location = "westeurope"
}

resource "azurerm_storage_account" "web" {
  name                     = "okpterraformweb"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
  }
}



resource "azurerm_app_service_plan" "appservice" {
  name                = "okp-terraform-sp"
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
  name                = "okp-terraform-app" 
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  app_service_plan_id = azurerm_app_service_plan.appservice.id
}
