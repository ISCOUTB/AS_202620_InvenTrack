variable "subscription_id" {
  description = "Azure subscription that hosts InvenTrack."
  type        = string
}

variable "region" {
  description = "Azure region for the registry and Container Apps environment."
  type        = string
  default     = "westeurope"
}

variable "image_tag" {
  description = "Container image tag to deploy."
  type        = string
  default     = "latest"
}