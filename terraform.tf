# TODO: Backend?
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.64.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "azurerm" {
  tenant_id       = "ef45594d-07dd-4e5e-bc95-0bc6b361e482"
  subscription_id = "9539bc24-8692-4fe2-871e-3733e84b1b73"
  features {}
}

