variable "location" {
  type        = string
  default     = "westeurope"
  description = "Where to store provisioned resources"
}

variable "backend_image" {
  type        = string
  description = "The Docker image to run for the backend"
}

variable "frontend_zip" {
  type        = string
  description = "URL to ZIP containing the compiled frontend"
}
