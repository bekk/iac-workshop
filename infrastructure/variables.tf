variable "location" {
  type        = string
  default     = "westeurope"
  description = "Where to store provisioned resources"
}

variable "backend_image" {
  type        = string
  default     = "ghcr.io/evenh/iac-workshop-backend:latest"
  description = "The Docker image to run for the backend"
}
