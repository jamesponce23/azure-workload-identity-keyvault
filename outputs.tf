output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "app_identity_client_id" {
  description = "Client ID of the app's user-assigned managed identity (for DefaultAzureCredential)."
  value       = azurerm_user_assigned_identity.app.client_id
}

output "app_identity_principal_id" {
  value = azurerm_user_assigned_identity.app.principal_id
}

output "container_app_name" {
  value = azurerm_container_app.app.name
}

output "storage_account_name" {
  value = azurerm_storage_account.target.name
}

output "private_endpoint_enabled" {
  value = var.enable_private_endpoint
}

output "secrets_in_config" {
  description = "By design."
  value       = "none"
}
