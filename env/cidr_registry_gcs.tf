# Publica o cidr-registry.txt validado no bucket GCS do projeto shared (parâmetros do módulo).
# Corre depois de data.external.cidr_registry_validation.

locals {
  cidr_gcs_upload_enabled = var.cidr_registry_gcs_bucket != null && var.cidr_registry_gcs_bucket != ""
}

resource "google_storage_bucket_object" "cidr_registry" {
  count    = local.cidr_gcs_upload_enabled ? 1 : 0
  provider = google.shared

  bucket = var.cidr_registry_gcs_bucket
  name   = var.cidr_registry_gcs_object

  source       = abspath("${var.cidr_validation_infra_directory}/config/cidr-registry.txt")
  content_type = "text/plain; charset=utf-8"

  depends_on = [data.external.cidr_registry_validation]
}
