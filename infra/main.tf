locals {
  service_name = "inventrack-api"
  resource_group = "inventrack-rg"
  registry_name  = "inventrack${substr(md5(var.subscription_id), 0, 8)}"
  image          = "${azurerm_container_registry.api.login_server}/${local.service_name}:${var.image_tag}"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group
  location = var.region
}

resource "azurerm_container_registry" "api" {
  name                = local.registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "inventrack-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "inventrack-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_container_app" "api" {
  name                         = local.service_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name

  ingress {
    external_enabled = true
    target_port      = 10000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = azurerm_container_registry.api.login_server
    username             = azurerm_container_registry.api.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.api.admin_password
  }

  template {
    min_replicas = 0
    max_replicas = 2

    container {
      name   = local.service_name
      image  = local.image
      cpu    = 0.25
      memory = "0.5Gi"

      liveness_probe {
        transport = "HTTP"
        port      = 10000
        path      = "/health"
      }
    }
  }
}