locals {
  required_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "vpcaccess.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each                   = toset(local.required_apis)
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false   # keep APIs enabled if this resource is destroyed
  disable_dependent_services = false   # safer for shared projects
}
