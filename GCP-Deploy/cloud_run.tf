resource "google_cloud_run_v2_service" "default" {
  name     = "${var.prefix}-service"
  location = var.region

  template {
    containers {
      # Simple public Hello World container
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
}

# Make the Cloud Run service publicly accessible
resource "google_cloud_run_v2_service_iam_member" "noauth" {
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
