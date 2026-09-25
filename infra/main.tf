locals {
  service_name = "inventrack-api"
  repository   = "inventrack"
  image        = "${var.region}-docker.pkg.dev/${var.project_id}/${local.repository}/${local.service_name}:${var.image_tag}"
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "api" {
  location      = var.region
  repository_id = local.repository
  description   = "Container images for InvenTrack"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry]
}

resource "google_cloud_run_v2_service" "api" {
  name     = local.service_name
  location = var.region

  deletion_protection = false

  template {
    containers {
      image = local.image

      ports {
        container_port = 10000
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }

  depends_on = [google_artifact_registry_repository.api]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.api.name
  location = google_cloud_run_v2_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}