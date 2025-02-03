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
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
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

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "taskmanager-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_username = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
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
      "sudo apt-get update",
      "sudo apt-get install -y docker.io docker-compose",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
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