variable "project_id" {
  type = string
}

variable "cidr_gate_token" {
  type        = string
  description = "Dependência de ordenação: validação CIDR e, se aplicável, upload GCS."
  default     = ""
}

variable "services" {
  description = "Optional override list of API service names to enable (default: CRM, Compute, IAM)."
  type        = list(string)
  default     = null
  nullable    = true
}
