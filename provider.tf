terraform {
  required_version = ">= 1.3"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Utilise project_id du YAML par défaut
locals {
  project = var.project_id != "" ? var.project_id : yamldecode(file(var.config_file)).project_id
}

provider "google" {
  project = local.project
}