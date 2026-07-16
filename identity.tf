# Workload identity. A user-assigned managed identity is the app's only
# "credential" — there is no secret. User-assigned (vs system-assigned) so the
# identity can hold its Key Vault role BEFORE the Container App is created and
# reads the secret, avoiding a create-time circular dependency.

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-app"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# App identity -> read secrets from Key Vault (data-plane, RBAC — no access policies).
resource "azurerm_role_assignment" "app_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# App identity -> read blob data (the "authenticate to another Azure resource
# with the same identity" half of the demo). Data-plane RBAC, no keys.
resource "azurerm_role_assignment" "app_blob_reader" {
  scope                = azurerm_storage_account.target.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Deployer (you) -> write secrets, so `azurerm_key_vault_secret` can seed the
# demo secret on an RBAC vault (which has no access policies).
resource "azurerm_role_assignment" "deployer_kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
}

# RBAC is eventually consistent — give role assignments a moment to propagate
# before the secret write / Container App secret read that depend on them.
resource "time_sleep" "rbac_propagation" {
  create_duration = "45s"
  depends_on = [
    azurerm_role_assignment.app_kv_secrets_user,
    azurerm_role_assignment.deployer_kv_secrets_officer,
  ]
}
