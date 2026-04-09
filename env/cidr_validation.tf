# ---------------------------------------------------------------------------
# TEMPORARY (demo / presentation): CIDR validation is OFF.
# To re-enable: restore the `data "external" "cidr_registry_validation"` block
# from version control and wire `main.tf` + `cidr_registry_gcs.tf` back to it.
# ---------------------------------------------------------------------------

locals {
  cidr_registry_validation_token = "disabled-for-demo"
}

# data "external" "cidr_registry_validation" {
#   program = [
#     var.cidr_python_executable,
#     abspath("${path.module}/scripts/cidr_registry_gcs_sync.py"),
#     "validate",
#   ]
#   query = {
#     peer_env     = var.peer_env
#     project_id   = var.project_id
#     vpc_cidr     = var.vpc_cidr
#     subnets_json = jsonencode(var.subnets)
#     bucket       = coalesce(var.cidr_registry_gcs_bucket, "")
#     object       = var.cidr_registry_gcs_object
#   }
# }
