variable "project" {}
variable "domain" {}

output "ssl_certificate_id" {
  value = google_compute_managed_ssl_certificate.cert.id
}
output "ssl_policy_id" {
  value = google_compute_ssl_policy.this.id
}

locals {
  managed_domains = tolist([var.domain])
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate#example-usage---managed-ssl-certificate-recreation
resource "random_id" "certificate" {
  byte_length = 4
  prefix      = "cert-"

  keepers = {
    domains = join(",", local.managed_domains)
  }
}

resource "google_compute_managed_ssl_certificate" "cert" {
  name     = random_id.certificate.hex

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = local.managed_domains
  }
}

resource "google_compute_ssl_policy" "this" {
  name            = "${var.project}-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}