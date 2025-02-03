provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "taskmanager-rg"
  location = "Germany West Central"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "taskmanager-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "taskmanager-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "taskmanager-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "taskmanager-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "taskmanager-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "taskmanager-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  admin_username = "azureuser"
  admin_password = "P@ssw0rd1234!"

  network_interface_ids = [azurerm_network_interface.nic.id]

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

  custom_data = filebase64("${path.module}/scripts/setup.sh")
}

resource "null_resource" "deploy" {
  depends_on = [azurerm_linux_virtual_machine.vm]

  provisioner "file" {
    source      = "../docker/docker-compose.yml"
    destination = "/home/azureuser/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file("~/.ssh/id_rsa")
      host        = azurerm_public_ip.public_ip.ip_address
    }
  }

  provisioner "file" {
    source      = "../docker/.env"
    destination = "/home/azureuser/.env"

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file("~/.ssh/id_rsa")
      host        = azurerm_public_ip.public_ip.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/azureuser",
      "docker-compose up -d"
    ]

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file("~/.ssh/id_rsa")
      host        = azurerm_public_ip.public_ip.ip_address
    }
  }
}