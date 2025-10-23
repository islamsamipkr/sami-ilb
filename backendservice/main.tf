# Backend Service régional pour Internal ALB
resource "google_compute_region_backend_service" "backend" {
  name                  = var.name
  region                = var.region
  project               = var.project_id
  protocol              = var.protocol
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = var.timeout_sec
  
  dynamic "backend" {
    for_each = var.negs
    content {
      group           = backend.value
      balancing_mode  = var.balancing_mode
      capacity_scaler = var.capacity_scaler
    }
  }
  
  dynamic "log_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      enable      = true
      sample_rate = var.log_sample_rate
    }
  }
}
