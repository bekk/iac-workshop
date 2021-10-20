terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.64.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
}

provider "azurerm" {
  // These values must be changed if the workshop is run in a new subscription
  tenant_id       = "a835f6a8-f507-45ec-a34e-17a0b73fd399"
  subscription_id = "4922867b-a15c-40aa-b9be-dfdf2782cbf7"
  features {}
}

