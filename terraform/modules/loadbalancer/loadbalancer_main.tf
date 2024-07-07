variable "project" {}
variable "region" {}
variable "suffix" {}
variable "cloudrun_service_name" {}
variable "ssl_certificate_id" {}
variable "ssl_policy_id" {}
variable "iap_member_groups" {}
variable "iap_client_id" {}
variable "iap_client_secret" {}
variable "domain" {}

# Aレコードに設定するIP Addressです。
resource "google_compute_global_address" "lb_address" {
  name = format(
    "iap-cloudrun-ip-%s",
    var.suffix,
  )
}

# ロードバランサーバックエンド
resource "google_compute_backend_service" "app" {
  name = format(
    "backend-service-%s",
    var.suffix,
  )
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  backend {
    group = google_compute_region_network_endpoint_group.app_neg.id
  }
  iap {
    oauth2_client_id     = var.iap_client_id
    oauth2_client_secret = var.iap_client_secret
  }
}

# Cloud RunのサービスにServerless NEGを追加
resource "google_compute_region_network_endpoint_group" "app_neg" {
  name                  = "serverless-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    # リクエストの送信先CloudRun
    service = var.cloudrun_service_name
  }
}

# ロードバランサ
resource "google_compute_url_map" "default" {
  name = format(
    "url-map-%s",
    var.suffix,
  )
  # デフォルト
  default_service = google_compute_backend_service.app.id
}

resource "google_compute_target_https_proxy" "this" {
  name = format(
    "https-proxy-%s",
    var.suffix
  )
  url_map = google_compute_url_map.default.id
  ssl_certificates = [var.ssl_certificate_id]
  ssl_policy       = var.ssl_policy_id
}

# フロントエンドの実設定
resource "google_compute_global_forwarding_rule" "default" {
  name = format(
    "forwarding-rule-%s",
    var.suffix,
  )
  ip_address  = google_compute_global_address.lb_address.id
  ip_protocol = "TCP"
  port_range  = "443"
  target      = google_compute_target_https_proxy.this.id
}

# httpへのアクセスはhttpsへ
resource "google_compute_url_map" "https_redirect" {
  name = "https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# IAPを経由してアクセスできるユーザーを設定します
resource "google_iap_web_backend_service_iam_binding" "binding_default" {
  project             = var.project
  web_backend_service = google_compute_backend_service.app.name
  role                = "roles/iap.httpsResourceAccessor"
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_web_backend_service_iam#member/members
  # userの指定のほか、Google Groupやdomainなどの指定ができると書かれています
  members             = var.iap_member_groups
}