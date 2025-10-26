resource "google_project_service" "compute" {
  project             = var.project_id
  service             = "compute.googleapis.com"
  disable_on_destroy  = false
  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}
