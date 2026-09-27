output "deploy_summary" {
  value = {
    for env, cfg in local.environnements :
    env => {
      deploy_id = random_id.deploy[env].hex
      image_tag = "${var.nom_projet}:${var.version_app}"
      replicas  = cfg.replicas
    }
  }
}
output "version" { value = var.version_app }
output "commit" { value = var.commit_sha }
