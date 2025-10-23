output "neg_self_link" {
  value = {
    for region, neg in google_compute_region_network_endpoint_group.neg :
    region => neg.self_link
  }
}
