# Validação de CIDR obrigatória: falha no plan/apply antes de criar recursos na GCP.
# Usamos data.external (não null_resource + local-exec): o provisioner do null_resource só
# corre no apply; o programa do external corre também no terraform plan.
#
# Requisito na máquina/CI que executa Terraform: python3 + PyYAML (pip install -r env/scripts/requirements-cidr.txt).

data "external" "cidr_registry_validation" {
  program = concat(
    [
      var.cidr_python_executable,
      abspath("${path.module}/scripts/validate_cidr_registry.py"),
      "--external",
    ],
    [abspath(var.cidr_validation_infra_directory)],
  )
}
