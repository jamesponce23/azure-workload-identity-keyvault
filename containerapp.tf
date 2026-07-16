# Container Apps environment, VNet-injected into snet-app (internal only — no
# public ingress). Consumption plan: scales to zero, covered by the monthly
# free grant.

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-zero-secrets"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_container_app_environment" "env" {
  name                       = "cae-zero-secrets"
  location                   = local.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  infrastructure_subnet_id       = azurerm_subnet.app.id
  internal_load_balancer_enabled = true

  tags = local.tags
}

# The app itself. Its ONLY identity is the user-assigned managed identity; it
# holds no secret material. The Key Vault secret is pulled by that identity and
# surfaced to the container as an env var — nothing sensitive in code or config.
resource "azurerm_container_app" "app" {
  name                         = "ca-zero-secrets"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  # Secret sourced from Key Vault via the managed identity (no value stored here).
  secret {
    name                = "downstream-api-key"
    identity            = azurerm_user_assigned_identity.app.id
    key_vault_secret_id = azurerm_key_vault_secret.demo.versionless_id
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      # App reads the Key Vault-backed secret from an env var. In real code this
      # is DefaultAzureCredential + SecretClient; here the platform injects it.
      env {
        name        = "DOWNSTREAM_API_KEY"
        secret_name = "downstream-api-key"
      }
      env {
        name  = "STORAGE_ACCOUNT"
        value = azurerm_storage_account.target.name
      }
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.app.client_id
      }
    }
  }

  ingress {
    external_enabled = false # internal to the VNet only
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  # The identity must already hold Key Vault Secrets User (and it must have
  # propagated) before the app can resolve the secret reference.
  depends_on = [
    azurerm_role_assignment.app_kv_secrets_user,
    time_sleep.rbac_propagation,
  ]

  tags = local.tags
}
