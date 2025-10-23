terraform {
  cloud {
    organization = "sami600"
    
    workspaces {
      tags = ["internal-loadbalancer", "sami-ilb"]
    }
  }
}