# Configuration file path
variable "config_file" {
  description = "Chemin vers le fichier de configuration YAML"
  type        = string
  default     = "config.yaml"
}

# Project ID - can be overridden, otherwise uses value from config.yaml
variable "project_id" {
  description = "GCP Project ID (defaults to config.yaml value)"
  type        = string
  default     = ""
}