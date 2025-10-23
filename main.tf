# ============================================================================
# INTERNAL APPLICATION LOAD BALANCER - Main Configuration
# ============================================================================

# Charger la configuration depuis config.yaml
locals {
  config = yamldecode(file(var.config_file))
}

# ============================================================================
# 1. IP ADDRESSES INTERNES RÉSERVÉES (une par région)
# ============================================================================
resource "google_compute_address" "internal_lb_ip" {
  for_each = toset(local.config.regions)
  
  name         = "${local.config.prefix}-ip-${each.key}"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  subnetwork   = local.config.subnetworks[each.key]
  region       = each.key
  project      = local.config.project_id
}

# ============================================================================
# 2. CERTIFICAT SSL (Self-managed)
# ============================================================================
resource "google_compute_ssl_certificate" "lb_cert" {
  name        = "${local.config.prefix}-ssl-cert"
  private_key = file(local.config.private_key_path)
  certificate = file(local.config.certificate_path)
  project     = local.config.project_id

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# 3. NETWORK ENDPOINT GROUPS (NEGs) pour Cloud Run
# ============================================================================
module "networkendpointgroup" {
  source = "./networkendpointgroup"
  
  for_each = {
    for service in local.config.cloudrun_services :
    service.name => service
  }
  
  project_id       = local.config.project_id
  name             = "${local.config.prefix}-${each.value.name}-neg"
  cloudrun_service = each.value.name
  regions          = local.config.regions
}

# ============================================================================
# 4. BACKEND SERVICES (un par région)
# ============================================================================
module "backendservice" {
  source = "./backendservice"
  
  for_each = toset(local.config.regions)
  
  project_id  = local.config.project_id
  name        = "${local.config.prefix}-backend-${each.key}"
  region      = each.key
  protocol    = local.config.backend.protocol
  timeout_sec = local.config.backend.timeout_sec
  
  # Collecter tous les NEG self_links pour cette région
  negs = [
    for service_name, neg_module in module.networkendpointgroup :
    neg_module.neg_self_link[each.key]
  ]
  
  balancing_mode   = local.config.backend.balancing_mode
  capacity_scaler  = local.config.backend.capacity_scaler
  enable_logging   = local.config.backend.enable_logging
  log_sample_rate  = local.config.backend.log_sample_rate
}

# ============================================================================
# 5. URL MAPS (un par région)
# ============================================================================
resource "google_compute_region_url_map" "url_map" {
  for_each = toset(local.config.regions)
  
  name            = "${local.config.prefix}-url-map-${each.key}"
  region          = each.key
  project         = local.config.project_id
  default_service = module.backendservice[each.key].backend_service_id
}

# ============================================================================
# 6. HTTPS TARGET PROXY (un par région)
# ============================================================================
resource "google_compute_region_target_https_proxy" "https_proxy" {
  for_each = toset(local.config.regions)
  
  name             = "${local.config.prefix}-https-proxy-${each.key}"
  region           = each.key
  project          = local.config.project_id
  url_map          = google_compute_region_url_map.url_map[each.key].id
  ssl_certificates = [google_compute_ssl_certificate.lb_cert.id]
}

# ============================================================================
# 7. FORWARDING RULES (un par région) - Point d'entrée du Load Balancer
# ============================================================================
resource "google_compute_forwarding_rule" "forwarding_rule" {
  for_each = toset(local.config.regions)
  
  name                  = "${local.config.prefix}-fwd-rule-${each.key}"
  region                = each.key
  project               = local.config.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = local.config.forwarding_rule.port_range
  target                = google_compute_region_target_https_proxy.https_proxy[each.key].id
  ip_address            = google_compute_address.internal_lb_ip[each.key].address
  
  depends_on = [google_compute_address.internal_lb_ip]
}
