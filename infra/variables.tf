variable "project_id" {
  description = "Google Cloud project that hosts InvenTrack."
  type        = string
}

variable "region" {
  description = "Google Cloud region for the registry and Cloud Run service."
  type        = string
  default     = "europe-west1"
}

variable "image_tag" {
  description = "Container image tag to deploy."
  type        = string
  default     = "latest"
}