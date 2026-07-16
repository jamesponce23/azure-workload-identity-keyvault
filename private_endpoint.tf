# Private Endpoint path — the "real" premise. Toggle on with
# enable_private_endpoint = true (adds ~$7/mo while it exists). When on, Key
# Vault's public endpoint is disabled (see keyvault.tf) and the app reaches the
# vault over a private IP, resolved by the private DNS zone.

resource "azurerm_private_dns_zone" "kv" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  count                 = var.enable_private_endpoint ? 1 : 0
  name                  = "kv-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv[0].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "kv" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-kv"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privatelink.id

  private_service_connection {
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv[0].id]
  }

  tags = local.tags
}
