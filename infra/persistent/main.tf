# infra/persistent/main.tf
#
# PERSISTENTE SCHICHT – wird praktisch nie destroyed.
# Hier lebt alles, was ein `terraform destroy` im vm/-Projekt
# überleben soll: der Data Disk mit deinen AI-Agent-Daten.
#
# Deployment: einmalig, dann in Ruhe lassen.
#   cd infra/persistent && terraform init && terraform apply

resource "azurerm_resource_group" "persistent" {
  name     = "rg-lab-persistent"
  location = var.location

  tags = {
    environment = "lab"
    layer       = "persistent"
    managed_by  = "terraform"
  }
}

resource "azurerm_managed_disk" "data" {
  name                 = "disk-lab-data"
  location             = azurerm_resource_group.persistent.location
  resource_group_name  = azurerm_resource_group.persistent.name
  storage_account_type = "Standard_LRS" # HDD, billigste Option
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  tags = {
    layer = "persistent"
  }

  # Schutz vor versehentlichem Löschen: Terraform verweigert dann
  # jeden destroy/replace dieser Ressource, bis man es explizit
  # wieder auf false setzt.
  lifecycle {
    prevent_destroy = true
  }
}
