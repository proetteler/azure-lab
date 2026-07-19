# infra/vm/main.tf
#
# WEGWERF-SCHICHT ("cattle") – jederzeit zerstörbar und reproduzierbar.
#   terraform apply    → VM steht in ~3 Min, fertig eingerichtet (cloud-init)
#   terraform destroy  → alles weg (keine persistente Schicht angebunden)

resource "azurerm_resource_group" "lab" {
  name     = "rg-${var.prefix}"
  location = var.location

  tags = {
    environment = "lab"
    layer       = "ephemeral"
    managed_by  = "terraform"
  }
}

# ------------------------------------------------------------------
# Netzwerk
# ------------------------------------------------------------------
resource "azurerm_virtual_network" "lab" {
  name                = "vnet-${var.prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "lab" {
  name                 = "snet-${var.prefix}"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "lab" {
  name                = "nsg-${var.prefix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_source
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "lab" {
  name                = "pip-${var.prefix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "lab" {
  name                = "nic-${var.prefix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab.id
  }
}

resource "azurerm_network_interface_security_group_association" "lab" {
  network_interface_id      = azurerm_network_interface.lab.id
  network_security_group_id = azurerm_network_security_group.lab.id
}

# ------------------------------------------------------------------
# VM mit cloud-init: richtet sich beim ersten Boot selbst ein
# (Docker, Python, uv) – siehe cloud-init.yaml
# ------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "lab" {
  name                = "vm-${var.prefix}-01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.lab.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username = var.admin_username
  }))
}

# ------------------------------------------------------------------
# Auto-Shutdown als Sicherheitsnetz
# ------------------------------------------------------------------
resource "azurerm_dev_test_global_vm_shutdown_schedule" "lab" {
  virtual_machine_id = azurerm_linux_virtual_machine.lab.id
  location           = azurerm_resource_group.lab.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "W. Europe Standard Time"

  notification_settings {
    enabled = false
  }
}
