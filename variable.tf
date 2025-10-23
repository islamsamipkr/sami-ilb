# Variables minimales - La config principale est dans config.yaml

variable "config_file" {
  description = "Chemin vers le fichier de configuration YAML"
  type        = string
  default     = "config.yaml"
}