locals {
  server_port = "8080"
  mgmt_port   = "8090"
}

resource "random_password" "jwt-secret" {
  length  = 64
  special = false
  lower   = true
  upper   = true
  number  = true
}

resource "azurerm_container_group" "backend" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${local.resource_prefix}backend"
  ip_address_type     = "Public"
  dns_name_label      = local.unique_id_raw
  os_type             = "Linux"

  container {
    name   = "backend"
    image  = var.backend_image
    cpu    = "1"
    memory = "1"

    ports {
      port     = local.server_port
      protocol = "TCP"
    }

    secure_environment_variables = {
      "JWT_SECRET" = random_password.jwt-secret.result
    }

    readiness_probe {
      http_get {
        path   = "/actuator/health"
        port   = local.mgmt_port
        scheme = "Http"
      }
    }
  }

  container {
    name   = "caddy"
    image  = "caddy"
    cpu    = "0.5"
    memory = "0.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 80
      protocol = "TCP"
    }

    volume {
      name                 = "aci-caddy-data"
      mount_path           = "/data"
      storage_account_name = azurerm_storage_account.aci_caddy.name
      storage_account_key  = azurerm_storage_account.aci_caddy.primary_access_key
      share_name           = azurerm_storage_share.aci_caddy.name
    }

    commands = ["caddy", "reverse-proxy", "--from", "${local.unique_id_raw}.westeurope.azurecontainer.io", "--to", "localhost:${local.server_port}"]
  }
}

resource "azurerm_storage_account" "aci_caddy" {
  name                      = "${local.unique_id_raw}acicaddy"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_storage_share" "aci_caddy" {
  name                 = "aci-caddy-data"
  storage_account_name = azurerm_storage_account.aci_caddy.name
  quota                = 10 # GB
}
