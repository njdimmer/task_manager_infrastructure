provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
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

resource "azurerm_network_security_group" "nsg" {
  name                = "taskmanager-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "taskmanager-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
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

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
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
      private_key = var.ssh_private_key
      host        = azurerm_public_ip.public_ip.ip_address
    }
  }

  provisioner "file" {
    source      = "../docker/.env"
    destination = "/home/azureuser/.env"

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = var.ssh_private_key
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
      private_key = var.ssh_private_key
      host        = azurerm_public_ip.public_ip.ip_address
    }
  }
}

output "vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}