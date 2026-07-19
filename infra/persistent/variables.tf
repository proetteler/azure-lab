# infra/persistent/variables.tf

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "switzerlandnorth"
}

variable "data_disk_size_gb" {
  description = "Grösse des persistenten Data Disks in GB"
  type        = number
  default     = 32 # Standard HDD 32 GB ≈ 1.50 CHF/Monat
}
