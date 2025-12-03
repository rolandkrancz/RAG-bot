terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rag_bot" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "rag_bot" {
  name                = "${var.app_name}-logs"
  location            = azurerm_resource_group.rag_bot.location
  resource_group_name = azurerm_resource_group.rag_bot.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_container_app_environment" "rag_bot" {
  name                       = "${var.app_name}-env"
  location                   = azurerm_resource_group.rag_bot.location
  resource_group_name        = azurerm_resource_group.rag_bot.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.rag_bot.id

  tags = var.tags
}

locals {
  openai_secret_enabled = trimspace(nonsensitive(var.openai_api_key)) != ""
  registry_auth_enabled = alltrue([
    trimspace(var.registry_server) != "",
    trimspace(var.registry_username) != "",
    trimspace(nonsensitive(var.registry_password)) != ""
  ])
}

resource "azurerm_container_app" "rag_bot" {
  name                         = var.app_name
  container_app_environment_id = azurerm_container_app_environment.rag_bot.id
  resource_group_name          = azurerm_resource_group.rag_bot.name
  revision_mode                = "Single"

  dynamic "secret" {
    for_each = local.openai_secret_enabled ? [var.openai_api_key] : []
    content {
      name  = "openai-api-key"
      value = secret.value
    }
  }

  dynamic "secret" {
    for_each = local.registry_auth_enabled ? [var.registry_password] : []
    content {
      name  = "registry-password"
      value = secret.value
    }
  }

  dynamic "registry" {
    for_each = local.registry_auth_enabled ? [1] : []
    content {
      server               = var.registry_server
      username             = var.registry_username
      password_secret_name = "registry-password"
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "rag-bot"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.openai_secret_enabled ? [var.openai_api_key] : []
        content {
          name        = "OPENAI_API_KEY"
          secret_name = "openai-api-key"
        }
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      template[0].container[0].image # Allow image updates without terraform
    ]
  }
}
