variable "project" {}
variable "support_email" {}
output "google_iap_client_client_id" {
  value = google_iap_client.this.client_id
}
output "google_iap_client_secret" {
  value = google_iap_client.this.secret
}

resource "google_iap_brand" "iap_brand" {
  support_email     = var.support_email
  application_title = "IAP App name"
  project           = var.project
}

# ついgoogle_iap_brandをGoogle Consoleから作ってしまった場合には、以下のコマンドでbrandを確認してgoogle_iap_clientを設定する
# gcloud alpha iap oauth-brands list
resource "google_iap_client" "this" {
  display_name = "IAP client"
  brand        = google_iap_brand.iap_brand.name
}