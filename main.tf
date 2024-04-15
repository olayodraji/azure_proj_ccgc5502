provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "web" {
  name     = "web-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "web" {
  name                = "web-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.web.name
  virtual_network_name = azurerm_virtual_network.web.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "web" {
  name                = "web-public-ip"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "web" {
  name                      = "web-nic"
  location                  = azurerm_resource_group.web.location
  resource_group_name       = azurerm_resource_group.web.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                  = "web-vm"
  location              = azurerm_resource_group.web.location
  resource_group_name   = azurerm_resource_group.web.name
  network_interface_ids = [azurerm_network_interface.web.id]
  size                  = "Standard_DS1_v2"
  admin_username        = "azureuser"
  admin_password        = "rajo@1234!"  # Replace with your desired password
  disable_password_authentication = true

admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")  # Path to your SSH public key file
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }


provisioner "local-exec" {
  command = "/usr/bin/ansible-playbook -i ${azurerm_network_interface.web.private_ip_address}, n01460461-playbook.yml"
  interpreter = ["bash", "-c"]
  when      = create
  environment = {
    ANSIBLE_HOST_KEY_CHECKING = "False"
  }
}

}


output "public_ip" {
  value = azurerm_public_ip.web.ip_address
}
