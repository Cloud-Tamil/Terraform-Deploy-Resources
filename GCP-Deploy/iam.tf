resource "google_service_account" "sa" {
  account_id   = "${var.prefix}-sa"
  display_name = "Demo Service Account"
}

resource "google_project_iam_member" "sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.sa.email}"
}
