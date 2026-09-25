output "service_url" {
  description = "Public HTTPS URL of the InvenTrack API."
  value       = google_cloud_run_v2_service.api.uri
}

output "image" {
  description = "Container image deployed by Cloud Run."
  value       = local.image
}