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

variable "frontend_zip" {
  type        = string
  default     = "https://github.com/bekk/iac-workshop/releases/latest/download/iac-workshop-frontend.zip"
  description = "URL to ZIP containing the compiled frontend"
}
