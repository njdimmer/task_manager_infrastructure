variable "ssh_private_key" {
  description = "SSH Private Key for VM access"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH Public Key for VM access"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "acr_username" {
  type = string
}

variable "acr_password" {
  type = string
}