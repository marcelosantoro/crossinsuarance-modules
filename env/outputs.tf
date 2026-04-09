output "project_id" {
  value = var.project_id
}

output "network_self_link" {
  value = module.vpc.network_self_link
}

output "subnet_self_links" {
  value = module.vpc.subnet_self_links
}

output "cidr_registry_gcs_uri" {
  description = "gs:// URI do registo CIDR publicado (se upload estiver ativo)."
  value       = local.cidr_gcs_upload_enabled ? "gs://${var.cidr_registry_gcs_bucket}/${var.cidr_registry_gcs_object}" : null
}
