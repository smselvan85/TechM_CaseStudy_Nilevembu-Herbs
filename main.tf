## Resource group in Southeast Asia using the value of resource_group1 and the location1 of the location1 variable
## defined in the terraform.tfvars file.
resource "azurerm_resource_group" "searg" {
  name     = var.resource_group1
  location = var.location1
  tags     = var.global_settings.tags
}

## Creating an availability set
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set
resource "azurerm_availability_set" "Seaaset" {
  name                         = "sea-aset"
  location                     = azurerm_resource_group.searg.location
  resource_group_name          = azurerm_resource_group.searg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = var.global_settings.tags
}

## NSG to allow http, rdp connections.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "Seansg" {
  name                = "nsg1"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name

  ## rule to allow Ansible to connect to each WEb VM from Jump/Managemnt host
  ## source_address_prefix will be the IP of JumpSubnet/My local IP

  security_rule {
    name                       = "allowWinRm"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = var.management_source
    destination_address_prefix = "*"
  }

  ## rule to allow web clients to connect to the web app
  security_rule {
    name                       = "allowPublicWeb"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  ## rule to allow rdp connection from Jump/management host to the VMs
  security_rule {
    name                       = "allowRDP"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.global_settings.tags
}

## NSG to allow rdp connections to Jump Host.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "Jumpnsg" {
  name                = "nsg2"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name

  security_rule {
    name                       = "allowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

## Virtual Network for Southeast Asia region
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "vnet1" {
  name                = "seavnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name
  tags                = var.global_settings.tags
}

## subnet1 for webservers in the vnet1 ensuring the Vnet is created first (depends_on)
resource "azurerm_subnet" "Subnet1" {
  name                 = "websubnet"
  resource_group_name  = azurerm_resource_group.searg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.1.1.0/24"]

  depends_on = [
    azurerm_virtual_network.vnet1
  ]
}

## subnet2 for Jump host in the same vnet1 ensuring the vnet is created first (depends_on)
resource "azurerm_subnet" "Subnet2" {
  name                 = "jumpsubnet"
  resource_group_name  = azurerm_resource_group.searg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.1.2.0/24"]

  depends_on = [
    azurerm_virtual_network.vnet1
  ]
}

## You need a public IP to assign to the load balancer for client applications to 
## connect to the web app. Ensure this is static otherwise, the deployment will go through without
## error but an IP will not be assigned.
resource "azurerm_public_ip" "Lbip" {
  name                = "publiclbip"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name
  allocation_method   = "Static"
}

## We'll need public IPs for each VM for Ansible to connect to and to deploy the web app to.
resource "azurerm_public_ip" "Vmips" {
  count               = 2
  name                = "publicvmip-${count.index}"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.domain_name_prefix}-${count.index}"
}

## Nic for each VM. Using the count property to create two vNIcs while using ${count.index}
## to refer to each VM which will be defined in an array
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "Webnic" {
  count               = 2
  name                = "web-nic-${count.index}"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name

  ## Simple ip configuration for each vNic
  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.Subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Vmips[count.index].id
  }

  ## Ensure the subnet is created first before creating these vNics.
  depends_on = [
    azurerm_subnet.Subnet1
  ]
}

## We'll need public IPs for each VM for Ansible to connect to and to deploy the web app to.
resource "azurerm_public_ip" "Jumpips" {
  count               = 1
  name                = "jumpvmip-${count.index}"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name
  allocation_method   = "Dynamic"
  //domain_name_label   = "${var.domain_name_prefix}-${count.index}"
}

## Nic for Jump Host. Using the count property to create two vNIcs while using ${count.index}
## to refer to each VM which will be defined in an array
resource "azurerm_network_interface" "Jumpnic" {
  count               = 1
  name                = "jump-nic-${count.index}"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name

  ## ip configuration for each Jump vNic
  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.Subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Jumpips[count.index].id
  }

  ## Ensure the subnet is created first before creating these vNics.
  depends_on = [
    azurerm_subnet.Subnet2
  ]
}

## Apply the WebNSG to each of the Web server's NICs
resource "azurerm_network_interface_security_group_association" "Webnsg-assoc" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.Webnic[count.index].id
  network_security_group_id = azurerm_network_security_group.Seansg.id
}

## Apply the JumpNSG to Jump Host VMs' NICs
resource "azurerm_network_interface_security_group_association" "Jumpnsg-assoc" {
  count                     = 1
  network_interface_id      = azurerm_network_interface.Jumpnic[count.index].id
  network_security_group_id = azurerm_network_security_group.Jumpnsg.id
}

## Create the load balancer with a frontend configuration using the public
## IP address created earlier.
resource "azurerm_lb" "LB" {
  name                = "sealoadbalancer"
  location            = azurerm_resource_group.searg.location
  resource_group_name = azurerm_resource_group.searg.name

  frontend_ip_configuration {
    name                 = "lb_frontend"
    public_ip_address_id = azurerm_public_ip.Lbip.id
  }
}

## Create and assign a backend address pool which will hold both VMs behind the load balancer
resource "azurerm_lb_backend_address_pool" "be_pool" {
  resource_group_name = azurerm_resource_group.searg.name
  loadbalancer_id     = azurerm_lb.LB.id
  name                = "BackEndAddressPool"
}

## load balancer NAT port forwarding
resource "azurerm_lb_nat_rule" "Lbnat" {
  resource_group_name            = azurerm_resource_group.searg.name
  loadbalancer_id                = azurerm_lb.LB.id
  name                           = "RDPAccess"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = "lb_frontend"
}

## Assign both vNics on the VMs to the backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "be_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.Webnic[count.index].id
  ip_configuration_name   = "ip_config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

## health probe which will periodically check for an open port 80
## on both VMs connected to the load balancer.
resource "azurerm_lb_probe" "lbprobe" {
  resource_group_name = azurerm_resource_group.searg.name
  loadbalancer_id     = azurerm_lb.LB.id
  name                = "http-running-probe"
  port                = 80
}

## rule on the load balancer to forward all incoming traffic on port 80
## to the VMs in the backend address pool usin the health probe defined above
## to know which VMs are available.
resource "azurerm_lb_rule" "lbrule" {
  resource_group_name            = azurerm_resource_group.searg.name
  loadbalancer_id                = azurerm_lb.LB.id
  name                           = "LBRule"
  probe_id                       = azurerm_lb_probe.lbprobe.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.be_pool.id
  frontend_ip_configuration_name = "lb_frontend"
  load_distribution              = "SourceIP "
}

## Create the two Windows VMs associating the vNIcs created earlier
resource "azurerm_windows_virtual_machine" "Webvms" {
  count                 = 2
  name                  = "webvm-${count.index}"
  location              = var.location1
  resource_group_name   = azurerm_resource_group.searg.name
  size                  = var.server_vm_size
  network_interface_ids = [azurerm_network_interface.Webnic[count.index].id]
  availability_set_id   = azurerm_availability_set.Seaaset.id
  computer_name         = "webvm-${count.index}"
  admin_username        = "vmadmin"
  admin_password        = "vmserver@2021"

  source_image_reference {
    publisher = var.server_vm_image_publisher
    offer     = var.server_vm_image_offer
    sku       = var.server_vm_image_sku
    version   = var.server_vm_image_version
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [
    azurerm_network_interface.Webnic
  ]
}

## Create Jump host windows VMs associating the Jump vNIcs created earlier
resource "azurerm_windows_virtual_machine" "Jumpvms" {
  count                 = 1
  name                  = "jumpvm-${count.index}"
  location              = var.location1
  resource_group_name   = azurerm_resource_group.searg.name
  size                  = var.server_vm_size
  network_interface_ids = [azurerm_network_interface.Jumpnic[count.index].id]
  computer_name         = "jumpvm-${count.index}"
  admin_username        = "vmadmin"
  admin_password        = "vmserver@2021"

  source_image_reference {
    publisher = var.server_vm_image_publisher
    offer     = var.server_vm_image_offer
    sku       = var.server_vm_image_sku
    version   = var.server_vm_image_version
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [
    azurerm_network_interface.Jumpnic
  ]
}

## Install the custom script VM extension to each Web servers VM. When the VM comes up,
## the extension will download the ConfigureRemotingForAnsible.ps1 script from the GitHub
## and execute it to open up WinRM for Ansible to connect to it from my local machine/Jump Host.
## exit code has to be 0
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension
resource "azurerm_virtual_machine_extension" "enablewinrm" {
  count                      = 2
  name                       = "enablewinrm"
  virtual_machine_id         = azurerm_windows_virtual_machine.Webvms[count.index].id
  publisher                  = "Microsoft.Compute"     ## az vm extension image list --location eastus Do not use Microsoft.Azure.Extensions here
  type                       = "CustomScriptExtension" ## az vm extension image list --location eastus Only use CustomScriptExtension here
  type_handler_version       = "1.9"                   ## az vm extension image list --location eastus
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
    }
SETTINGS
}

## Azure resource group in East US region using the value of resource_group2 and the location2 of the location variable
## defined in the terraform.tfvars file.
resource "azurerm_resource_group" "eusrg" {
  name     = var.resource_group2
  location = var.location2
  tags     = var.global_settings.tags
}

## NSG to allow rdp connections to Server11.
resource "azurerm_network_security_group" "Vmnsg" {
  name                = "nsg"
  location            = azurerm_resource_group.eusrg.location
  resource_group_name = azurerm_resource_group.eusrg.name

  security_rule {
    name                       = "allowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

## Virtual Network for East US region
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "vnet2" {
  name                = "eusvnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.eusrg.location
  resource_group_name = azurerm_resource_group.eusrg.name
  tags                = var.global_settings.tags
}

## subnet for webservers in the vnet2 ensuring the Vnet is created first (depends_on)
resource "azurerm_subnet" "subnet" {
  name                 = "eussubnet"
  resource_group_name  = azurerm_resource_group.eusrg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.2.1.0/24"]

  depends_on = [
    azurerm_virtual_network.vnet2
  ]
}

## We'll need public IPs for each VM to connect from Internet
resource "azurerm_public_ip" "Eusvmips" {
  name                = "vmip"
  location            = azurerm_resource_group.eusrg.location
  resource_group_name = azurerm_resource_group.eusrg.name
  allocation_method   = "Dynamic"
}

## Nic for Server11.
resource "azurerm_network_interface" "Vmnic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.eusrg.location
  resource_group_name = azurerm_resource_group.eusrg.name

  ## ip configuration for each Server11 vNic
  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Eusvmips.id
  }

  ## Ensure the subnet is created first before creating these vNics.
  depends_on = [
    azurerm_subnet.subnet
  ]
}

## Apply the NSG to Server11 VMs' NICs
resource "azurerm_network_interface_security_group_association" "Vmnsg-assoc" {
  network_interface_id      = azurerm_network_interface.Vmnic.id
  network_security_group_id = azurerm_network_security_group.Vmnsg.id
}

## Create Server11 windows VMs associating the vNIcs created earlier
resource "azurerm_windows_virtual_machine" "Vms" {
  name                  = "Server11"
  location              = var.location2
  resource_group_name   = azurerm_resource_group.eusrg.name
  size                  = var.server_vm_size
  network_interface_ids = [azurerm_network_interface.Vmnic.id]
  computer_name         = "Server11"
  admin_username        = "vmadmin"
  admin_password        = "vmserver@2021"

  source_image_reference {
    publisher = var.server_vm_image_publisher
    offer     = var.server_vm_image_offer
    sku       = var.server_vm_image_sku
    version   = var.server_vm_image_version
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [
    azurerm_network_interface.Vmnic
  ]
}

