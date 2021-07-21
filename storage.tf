# Storage Account for Southeast Asia region with RA-GRS
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "stg1" {
  name                     = "nvhseastg"
  resource_group_name      = azurerm_resource_group.searg.name
  location                 = azurerm_resource_group.searg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "RAGRS"

  tags = var.global_settings.tags
  depends_on = [
    azurerm_resource_group.searg
  ]
}


#Storage Account for East US Region with ZRS
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "stg2" {
  name                     = "nvheaststg"
  resource_group_name      = azurerm_resource_group.eusrg.name
  location                 = azurerm_resource_group.eusrg.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "ZRS"

  tags = var.global_settings.tags
  depends_on = [
    azurerm_resource_group.eusrg
  ]
}