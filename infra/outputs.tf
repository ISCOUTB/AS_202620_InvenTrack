output "service_url" {
  description = "Public HTTPS URL of the InvenTrack API."
  value       = "https://${azurerm_container_app.api.latest_revision_fqdn}"
}

output "image" {
  description = "Container image deployed by Azure Container Apps."
  value       = local.image
}

output "registry_name" {
  description = "Azure Container Registry name used by the deployment."
  value       = azurerm_container_registry.api.name
}