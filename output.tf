# Outputs du Load Balancer

output "internal_ip_addresses" {
  description = "IPs internes par région"
  value = {
    for region, ip in google_compute_address.internal_lb_ip :
    region => ip.address
  }
}

output "load_balancer_urls" {
  description = "URLs HTTPS du load balancer"
  value = {
    for region, ip in google_compute_address.internal_lb_ip :
    region => "https://${ip.address}"
  }
}
