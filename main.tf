# ============================================================================
# INTERNAL APPLICATION LOAD BALANCER - Main Configuration
# ============================================================================

# Charger la configuration depuis config.yaml
locals {
  config = yamldecode(file(var.config_file))
}

# ============================================================================
# 1. Reserve Internal IP ADDRESSES 
# ============================================================================
resource "google_compute_address" "internal_lb_ip" {
  for_each = toset(local.config.regions)
  
  name         = "chargemanagementipaddress"
  address_type = "INTERNAL"
  region       = "northamerica-northeast1"
  project      = var.project_id
}

/*# ============================================================================
# 2. CERTIFICAT SSL (Self-managed)
# ============================================================================
resource "google_compute_ssl_certificate" "lb_cert" {
  name        = "${var.project_prefix}-ssl-cert"
  private_key = "certs/certificate.crt"
  certificate = "certs/private.key"
  project     = var.project_id

  lifecycle {
    create_before_destroy = true
  }
}
*/
resource "google_certificate_manager_certificate" "gm" {
  name     = "ilb-gm-cert"
  location = var.region
  scope    = "REGIONAL"

}
# ============================================================================
# 3. NETWORK ENDPOINT GROUPS (NEGs) pour Cloud Run
# ============================================================================
module "networkendpointgroup" {
  source = "./networkendpointgroup"

  for_each = {
    for service in local.config.cloudrun_services :
    service.name => service
    if length(local.config.regions) <= 2
  }

  project_id       = var.project_id
  name             = "${var.project_prefix}-${each.value.name}-neg"
  cloudrun_service = each.value.name
  regions          = local.config.regions
}

# ============================================================================
# 4. BACKEND SERVICES (un par région)
# ============================================================================
module "backendservice" {
  source = "./backendservice"
  
  for_each = toset(local.config.regions)
  
  project_id  = var.project_id
  name        = "${var.project_prefix}-backend-${each.key}"
  region      = each.key
  protocol    = "HTTPS"
  timeout_sec = 30
  
  # Collecter tous les NEG self_links pour cette région
  negs = [
    for service_name, neg_module in module.networkendpointgroup :
    neg_module.neg_self_link[each.key]
  ]
  
  balancing_mode   = "UTILIZATION"
  capacity_scaler  = 1.0
  enable_logging   = true
  log_sample_rate  = 1.0
}

# ============================================================================
# 5. URL MAPS (un par région)
# ============================================================================
resource "google_compute_region_url_map" "url_map" {
  for_each = toset(local.config.regions)
  
  name            = "${var.project_prefix}-url-map-${each.key}"
  region          = each.key
  project         = var.project_id
  default_service = module.backendservice[each.key].backend_service_id
}

# ============================================================================
# 6. HTTPS TARGET PROXY (un par région)
# ============================================================================
resource "google_compute_region_target_https_proxy" "https_proxy" {
  for_each = toset(local.config.regions)
  
  name             = "${var.project_prefix}-https-proxy-${each.key}"
  region           = each.key
  project          = var.project_id
  url_map          = google_compute_region_url_map.url_map[each.key].id
  //ssl_certificates = [google_compute_ssl_certificate.lb_cert.id]
  ssl_certificates = [google_certificate_manager_certificate.gm.id]
}

# ============================================================================
# 7. FORWARDING RULES (un par région) - Point d'entrée du Load Balancer
# ============================================================================
resource "google_compute_forwarding_rule" "forwarding_rule" {
  for_each = toset(local.config.regions)
  
  name                  = "${var.project_prefix}-fwd-rule-${each.key}"
  region                = each.key
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.https_proxy[each.key].id
  ip_address            = google_compute_address.internal_lb_ip[each.key].address
  
  depends_on = [google_compute_address.internal_lb_ip]
}
