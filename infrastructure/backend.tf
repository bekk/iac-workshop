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
  ip_address_type     = "public"
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
}
