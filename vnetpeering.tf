# Vnet peering from East US Vnet to Southeast Asia Vnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
resource "azurerm_virtual_network_peering" "eus-to-sea" {
  name                      = "eus-to-sea"
  resource_group_name       = azurerm_resource_group.eusrg.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.vnet1, azurerm_virtual_network.vnet2]
}

# Vnet peering from Southeast Asia to East US
resource "azurerm_virtual_network_peering" "sea-to-eus" {
  name                         = "sea-to-eus"
  resource_group_name          = azurerm_resource_group.searg.name
  virtual_network_name         = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network.vnet1, azurerm_virtual_network.vnet2]
}