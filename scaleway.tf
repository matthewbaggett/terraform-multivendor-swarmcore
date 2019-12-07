provider "scaleway" {
  version         = "~> 1.12"
  access_key      = var.scaleway_access_key
  secret_key      = var.scaleway_secret_key
  organization_id = var.scaleway_organization_id
  zone            = var.scaleway_zone
  region          = var.scaleway_region
}

data "scaleway_image" "ubuntu" {
  count        = local.managers_scaleway > 0 ? 1 : 0
  architecture = "x86_64"
  name         = "Ubuntu Bionic"
}