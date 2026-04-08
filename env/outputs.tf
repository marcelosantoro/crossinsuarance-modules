output "project_id" {
  value = var.project_id
}

output "network_self_link" {
  value = module.vpc.network_self_link
}

output "subnet_self_links" {
  value = module.vpc.subnet_self_links
}
