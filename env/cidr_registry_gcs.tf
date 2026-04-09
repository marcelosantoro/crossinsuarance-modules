# ---------------------------------------------------------------------------
# TEMPORARY (demo / presentation): GCS incremental registry sync is OFF
# (null_resource count = 0). Re-enable after presentation — set count below.
# ---------------------------------------------------------------------------

locals {
  cidr_gcs_upload_enabled = var.cidr_registry_gcs_bucket != null && var.cidr_registry_gcs_bucket != ""
}

resource "null_resource" "cidr_registry_gcs" {
  count = 0 # TEMP: restore to (local.cidr_gcs_upload_enabled ? 1 : 0) when re-enabling CIDR sync

  triggers = {
    peer_env    = var.peer_env
    project_id  = var.project_id
    vpc_cidr    = var.vpc_cidr
    subnets     = sha256(jsonencode(var.subnets))
    bucket      = var.cidr_registry_gcs_bucket
    object      = var.cidr_registry_gcs_object
    python      = var.cidr_python_executable
    script_path = abspath("${path.module}/scripts/cidr_registry_gcs_sync.py")
  }

  # depends_on = [data.external.cidr_registry_validation]

  provisioner "local-exec" {
    command = "${var.cidr_python_executable} ${abspath("${path.module}/scripts/cidr_registry_gcs_sync.py")} apply"
    environment = {
      PEER_ENV     = var.peer_env
      PROJECT_ID   = var.project_id
      VPC_CIDR     = var.vpc_cidr
      SUBNETS_JSON = jsonencode(var.subnets)
      BUCKET       = var.cidr_registry_gcs_bucket
      OBJECT       = var.cidr_registry_gcs_object
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.python} ${self.triggers.script_path} destroy"
    environment = {
      PEER_ENV = self.triggers.peer_env
      BUCKET   = self.triggers.bucket
      OBJECT   = self.triggers.object
    }
  }
}
