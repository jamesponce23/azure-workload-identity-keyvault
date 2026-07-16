# Key Vault in RBAC mode (enable_rbac_authorization = true) — NO access policies.
# Access is granted only through Azure RBAC role assignments (see identity.tf).

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = local.kv_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # The whole point: authorize with RBAC, not access policies.
  rbac_authorization_enabled = true

  # Soft-delete on, purge protection OFF so the demo tears down cleanly (free).
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Public endpoint is disabled entirely when a private endpoint is used;
  # otherwise it stays reachable but RBAC-gated (and network-gated when
  # restrict_network = true).
  public_network_access_enabled = var.enable_private_endpoint ? false : true

  network_acls {
    bypass         = "AzureServices"
    default_action = (var.enable_private_endpoint || var.restrict_network) ? "Deny" : "Allow"

    # Allow the app subnet via its Key Vault service endpoint (free path).
    virtual_network_subnet_ids = var.enable_private_endpoint ? [] : [azurerm_subnet.app.id]

    # Optionally allow the deployer's public IP so the secret can be seeded
    # while the vault is locked down.
    ip_rules = var.restrict_network && var.deployer_ip != "" ? [var.deployer_ip] : []
  }

  tags = local.tags
}

# Demo secret. In a real app this might be a downstream API key or connection
# string; here it proves the app can retrieve it with only its identity.
resource "azurerm_key_vault_secret" "demo" {
  name         = "demo-downstream-api-key"
  value        = "not-a-real-secret-${local.suffix}"
  key_vault_id = azurerm_key_vault.kv.id

  # Wait for the deployer's Secrets Officer role to propagate.
  depends_on = [time_sleep.rbac_propagation]

  tags = local.tags
}
