# Private network. The app runs VNet-integrated; nothing is publicly exposed.

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-app"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
  tags                = local.tags
}

# App subnet: Container Apps environment is injected here. Delegated to
# Microsoft.App/environments. Service endpoints keep Key Vault + Storage traffic
# on the Azure backbone (free alternative to a private endpoint).
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.0.0/23"] # Container Apps Consumption needs at least /23

  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

  delegation {
    name = "container-apps"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Private Endpoints subnet — only used when enable_private_endpoint = true.
resource "azurerm_subnet" "privatelink" {
  name                 = "snet-privatelink"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.2.0/24"]
}
