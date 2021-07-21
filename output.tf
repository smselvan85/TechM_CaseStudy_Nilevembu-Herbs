## Return the load balancer's public IP address.
output "Load_Balancer_IP" {
  value = azurerm_public_ip.Lbip.ip_address
}

output "WebServer_Ips" {
  value = azurerm_public_ip.Vmips.*.ip_address
}

output "Jump_Server_Ips" {
  value = azurerm_public_ip.Jumpips.*.ip_address
}

output "Server11_Public_Ips" {
  value = azurerm_public_ip.Eusvmips.ip_address
}

output "Southeast_Storage_Primary_Location" {
  value = azurerm_storage_account.stg1.primary_location
}

output "Southeast_Storage_Secondary_Location" {
  value = azurerm_storage_account.stg1.secondary_location
}
