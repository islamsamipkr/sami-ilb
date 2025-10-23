terraform {
  cloud {
    organization = "Triforce"
    
    workspaces {
      tags = ["internal-loadbalancer", "sami-ilb"]
    }
  }
}