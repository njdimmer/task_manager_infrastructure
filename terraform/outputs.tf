output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "vm_username" {
  description = "Admin username of the VM"
  value       = azurerm_linux_virtual_machine.vm.admin_username
}