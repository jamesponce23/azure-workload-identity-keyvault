# Target resource the app authenticates to with the SAME managed identity —
# demonstrating identity-based, keyless access to a second Azure service.
# Shared-key auth is disabled: there is no account key to leak; callers must
# use Entra ID (RBAC) tokens.

resource "azurerm_storage_account" "target" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # No keys — force identity-based (Entra) access only.
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  # Restrict network to the app subnet (free service endpoint) when locking down.
  public_network_access_enabled = true
  network_rules {
    default_action             = var.restrict_network ? "Deny" : "Allow"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.restrict_network ? [azurerm_subnet.app.id] : []
    ip_rules                   = var.restrict_network && var.deployer_ip != "" ? [var.deployer_ip] : []
  }

  # The provider polls the blob data plane right after creating the account. With
  # keys disabled that poll uses Entra auth, so wait until the deployer's blob
  # role (in identity.tf) has propagated before the account is created.
  depends_on = [time_sleep.rbac_propagation]

  tags = local.tags
}

resource "azurerm_storage_container" "data" {
  name                  = "app-data"
  storage_account_id    = azurerm_storage_account.target.id
  container_access_type = "private"
}
