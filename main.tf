# ============================================================
#  JOUR 5 / 10 — Terraform : CI/CD
#  Pipeline GitHub Actions : plan sur PR, apply sur main
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local  = { source = "hashicorp/local", version = "~> 2.4" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }

  # En production : remote state partagé
  # backend "s3" {
  #   bucket = "mon-bucket-state"
  #   key    = "ci-cd/terraform.tfstate"
  #   region = "eu-west-3"
  # }
  backend "local" {}
}

provider "local" {}
provider "random" {}

locals {
  environnements = {
    dev     = { replicas = 1, log_level = "DEBUG", objectif = 20000 }
    staging = { replicas = 2, log_level = "INFO", objectif = 50000 }
    prod    = { replicas = 3, log_level = "WARNING", objectif = 100000 }
  }
}

# Config par environnement
resource "local_file" "config" {
  for_each = local.environnements

  filename = "${path.module}/output/${each.key}/config.json"
  content = jsonencode({
    environnement = each.key
    replicas      = each.value.replicas
    log_level     = each.value.log_level
    objectif_ca   = each.value.objectif
    deploye_par   = "GitHub Actions CI/CD"
    version       = var.version_app
    commit_sha    = var.commit_sha
  })
}

# ID de déploiement unique par run CI/CD
resource "random_id" "deploy" {
  for_each    = local.environnements
  byte_length = 4
  keepers = {
    version    = var.version_app
    commit_sha = var.commit_sha
  }
}

# Manifest de déploiement
resource "local_file" "manifest" {
  for_each = local.environnements
  filename = "${path.module}/output/${each.key}/manifest.json"
  content = jsonencode({
    environnement = each.key
    deploy_id     = random_id.deploy[each.key].hex
    image_tag     = "${var.nom_projet}:${var.version_app}"
    commit        = var.commit_sha
    replicas      = each.value.replicas
  })
}
