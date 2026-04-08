variable "project_id" {
  type = string
}

variable "services" {
  description = "Optional override list of API service names to enable (default: CRM, Compute, IAM)."
  type        = list(string)
  default     = null
  nullable    = true
}
