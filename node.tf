terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}


provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "app_group" {
  name     = "app_group"
  location = "Norway East"
}

resource "azurerm_virtual_network" "appvn" {
  name                = "apvn"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.app_group.location
  resource_group_name = azurerm_resource_group.app_group.name
}

resource "azurerm_subnet" "app_subn" {
  name                 = "app_subn"
  resource_group_name  = azurerm_resource_group.app_group.name
  virtual_network_name = azurerm_virtual_network.appvn.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "apppi" {
  name                = "app-pi"
  location            = azurerm_resource_group.app_group.location
  resource_group_name = azurerm_resource_group.app_group.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "app_ni" {
  name                = "app_ni"
  location            = azurerm_resource_group.app_group.location
  resource_group_name = azurerm_resource_group.app_group.name

  ip_configuration {
    name                          = "app_ipconfig"
    subnet_id                     = azurerm_subnet.app_subn.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.apppi.id
  }
}



resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "app_vm"
  location            = azurerm_resource_group.app_group.location
  resource_group_name = azurerm_resource_group.app_group.name

  size           = "Standard_D2s_v3"
  computer_name  = "appvm"
  admin_username = "adminuser"
  network_interface_ids = [azurerm_network_interface.app_ni.id]

  os_disk {
    name                 = "project-apposdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/appkey.pub")
   
  }


 



  tags = {
    environment = "dev"
    #just a comment
  }
}
