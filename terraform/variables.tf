variable "ssh_private_key" {
  description = "SSH Private Key for VM access"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH Public Key for VM access"
  type        = string
}