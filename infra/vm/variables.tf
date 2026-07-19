# infra/vm/variables.tf

variable "location" {
  description = "Azure Region (muss zur persistenten RG passen)"
  type        = string
  default     = "switzerlandnorth"
}

variable "prefix" {
  description = "Namenspräfix für alle Ressourcen"
  type        = string
  default     = "lab"
}

variable "admin_username" {
  description = "Linux Admin-Benutzername"
  type        = string
  default     = "patrick"
}

variable "ssh_public_key_path" {
  description = "Pfad zum öffentlichen SSH-Key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_size" {
  description = "VM-Grösse"
  type        = string
  default     = "Standard_B1s" # Free Tier: 750h/Monat im 1. Jahr
  # Für AI-Agent-Entwicklung mit Docker ggf. zu knapp (1 GB RAM).
  # Nächste Stufe: Standard_B2s (2 vCPU, 4 GB) ≈ 40 CHF/Mt bei 24/7,
  # aber nur ~1.30 CHF pro 24h-Session – bei destroy-Workflow egal.
}

variable "allowed_ssh_source" {
  description = "Quell-IP für SSH (CIDR). Besser als '*': deine IP, z.B. '85.1.2.3/32'"
  type        = string
  default     = "*"
}

variable "auto_shutdown_time" {
  description = "Tägliche Auto-Shutdown-Zeit (HHMM)"
  type        = string
  default     = "2300"
}

# --- Referenzen auf die persistente Schicht ---

variable "persistent_rg_name" {
  description = "Resource Group der persistenten Schicht"
  type        = string
  default     = "rg-lab-persistent"
}

variable "data_disk_name" {
  description = "Name des persistenten Data Disks"
  type        = string
  default     = "disk-lab-data"
}
