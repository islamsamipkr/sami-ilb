# Network Endpoint Group pour Cloud Run
resource "google_compute_region_network_endpoint_group" "neg" {
  for_each = toset(var.regions)
  
  name                  = "${var.name}-${each.key}"
  network_endpoint_type = "SERVERLESS"
  region                = each.key
  project               = var.project_id
  
  cloud_run {
    service = var.cloudrun_service
  }
}
