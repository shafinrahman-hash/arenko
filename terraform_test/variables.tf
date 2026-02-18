variable "environment" {
  description = "Deployment environment name (e.g., dev, test, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "environment must be lowercase letters, numbers, and hyphens only."
  }
}

variable "service" {
  description = "Service name (e.g., nginx)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service))
    error_message = "service must be lowercase letters, numbers, and hyphens only."
  }
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = null
}