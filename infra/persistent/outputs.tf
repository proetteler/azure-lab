# infra/persistent/outputs.tf

output "resource_group_name" {
  description = "Name der persistenten Resource Group (vom vm/-Projekt referenziert)"
  value       = azurerm_resource_group.persistent.name
}

output "data_disk_name" {
  description = "Name des Data Disks (vom vm/-Projekt referenziert)"
  value       = azurerm_managed_disk.data.name
}
