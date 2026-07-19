# infra/vm/outputs.tf

output "public_ip" {
  description = "Öffentliche IP der VM"
  value       = azurerm_public_ip.lab.ip_address
}

output "ssh_command" {
  description = "Fertiger SSH-Befehl"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.lab.ip_address}"
}
