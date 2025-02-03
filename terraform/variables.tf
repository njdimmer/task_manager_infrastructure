variable "ssh_private_key" {
  description = "SSH Private Key for VM access"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH Public Key for VM access"
  type        = string
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