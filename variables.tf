variable "nom_projet" {
  type    = string
  default = "etl_portfolio"
}
variable "version_app" {
  type    = string
  default = "1.0.0"
}
variable "commit_sha" {
  description = "SHA du commit Git (injecté par GitHub Actions)"
  type        = string
  default     = "local"
}
variable "environnement" {
  type    = string
  default = "dev"
}
