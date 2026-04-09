variable "project_id" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnets" {
  type = list(object({
    name   = string
    region = string
    cidr   = string
  }))
}

variable "shared_project_id" {
  type = string
}

variable "attach_shared_vpc_service_project" {
  type = bool
}

variable "peer_env" {
  type = string
}

variable "host_vpc_name" {
  type = string
}

variable "name_prefix" {
  type        = string
  default     = null
  nullable    = true
  description = "Optional prefix for peering names; defaults to project_id-peer_env."
}

variable "cidr_validation_infra_directory" {
  type        = string
  description = "Diretório raiz do stack do consumidor que contém config/cidr-registry.txt e config/environments.yaml (ex.: abspath do diretório infra/ dois níveis acima de infra/stacks)."
}

variable "cidr_python_executable" {
  type        = string
  default     = "python3"
  description = "Executável Python para o validador CIDR (data.external)."
}
